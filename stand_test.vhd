-- модуль тестирования правильности работы стенда в части корректрого анализа выходных сигналов блока
-- имитирует работу блока в плане корректной реакции на поступающие входные сигналы
-- схема проверяет последовательность поступления пар сигналов и ведет их подсчет, при этом на одной из 64 выходных 
-- линий формируется выходной импульс отрицательной полярности. номер линии на которой формируется выходной импульс
-- соответсвует количеству пришедших в систему пар входных импульсов 

-- входные сигналы
-- p_IN_IMP_LAS - импульс запуска лазера - сигнал положительной полярности
-- p_IN_IMP_GEN - импульс запуска генератора - сигнал отрицательной полярности

-- выходные сигналы
-- p_OUT_IMP - импульсы длительностью 2,5 мкс каждый

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity stand_test is
	port (		p_CLK:					in std_logic;
				p_i_RES:				in std_logic;
				p_IN_IMP_LAS:			in std_logic;								-- вход \ сигнал запуска лазера
				p_IN_IMP_GEN:			in std_logic;								-- вход \ сигнал запуска генератора
				p_OUT_IMP:				out std_logic_vector(63 downto 0)	-- выход \ имитация выхродного импульса блока по одному из каналов
			);
end entity;

architecture stand_test_behav of stand_test is

	type t_state is (st_gen, st_las, st_delay, st_imp);				--	состоянии конечного автомат проверки импульсного детектора
	SIGNAL s_FSM:t_state;

	SIGNAL s_CNT:					integer range 0 to 300 := 0;	
	SIGNAL s_IMP_CNT:				integer range 0 to 63 := 0;			-- количество выдаваемых импульсов при проверки импульсоного деиектора

	SIGNAL s_OUT_PORT:				std_logic_vector(63 downto 0) := x"FFFFFFFFFFFFFFFE";	-- имитация сигналов блока при работе
	SIGNAL s_BASE_DATA:				std_logic_vector(63 downto 0) := (others => '1');
	SIGNAL s_LAS_FILTER:			std_logic_vector(3 downto 0);		-- фильтр импульса запуска лазера
	SIGNAL s_GEN_FILTER:			std_logic_vector(3 downto 0);		-- фильтр импульма запуска генеретора

begin
	process (p_CLK)
	begin
		if rising_edge(p_CLK) then

			p_OUT_IMP <= s_BASE_DATA;
-- проверка стенда на сарабатывание от пачек импульсов 
		-- фильт сигнала запуска лазера
			s_LAS_FILTER(2 downto 0) <= s_LAS_FILTER(3 downto 1);
			s_LAS_FILTER(3) <= p_IN_IMP_LAS;
		-- фильтр сигнала запуска генератора
			s_GEN_FILTER(2 downto 0) <= s_GEN_FILTER(3 downto 1);
			s_GEN_FILTER(3) <= p_IN_IMP_GEN;

			if p_i_RES = '1' then
				s_OUT_PORT <= x"FFFFFFFFFFFFFFFE";
			else

				case s_FSM is

				-- проверка сигнала запуска генератора
					when st_gen =>	if s_GEN_FILTER = "0011" then
										s_FSM <= st_las;
										--s_CNT <= 0;
										--s_FSM <= st_delay;
									end if;

				-- проверка сигнала запуска лазера
					when st_las =>	if s_LAS_FILTER = "1100" then
											s_CNT <= 0;
											s_FSM <= st_delay;
										end if;

				-- задержка перед выдачей сигнала
					when st_delay => if s_CNT >= 100 then
										s_CNT <= 0;
										s_FSM <= st_imp;
									else
										s_CNT <= s_CNT + 1;
										s_FSM <= st_delay;
									end if;

				-- выдача сигнала на один из портов
					when st_imp =>	if s_CNT >= 105 then
										s_CNT <= 0;
										s_BASE_DATA <= (others => '1');
										s_OUT_PORT <= s_OUT_PORT(62 downto 0) & s_OUT_PORT(63);
										s_FSM <= st_gen;
										--s_FSM <= st_delay;
									else
										s_CNT <= s_CNT + 1;
										s_BASE_DATA <= s_OUT_PORT;
										s_FSM <= st_imp;
									end if;

					when others => s_FSM <= st_delay; --st_gen;

				end case;
			end if;
		end if;

	end process;
	
end architecture stand_test_behav;	