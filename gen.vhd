-- возможно лучше перепилить std_logoc_vector в integer 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity gen is
	generic(															 			
		constant c_length_impulse_gen: 		integer range 0 to 50 := 50; 			-- длительность импульса генератора
		constant c_length_impulse_laser: 	integer range 0 to 25 := 25; 			-- длительность импульса лазера
		constant c_delay_laser_after_gen:	integer range 0 to 128 := 110;		-- время задержки импульса лазера после выдачи импульса генератора
		constant c_impulse_period: 			integer range 0 to 600 := 600; 		-- период повторения пары импульсов в пачке по 4 импульса
		constant c_period_between_pack: 	integer range 0 to 85000 := 85000;	-- длительность интервала между пачками
	--	constant c_freq_six_khz:			integer range 0 to 8500 := 200;--8500;		-- длительность периода при работе на частоте 6 кГц
		constant c_base_work: 				integer range 0 to 5000000 := 5000000 --500000	-- длительность периода между импулсами при раьоте в режиме прогона (1000000)
		);

	port (	clk:				in	std_logic;
			p_in_rst: 			in	std_logic;								-- сигнал сброса
	      	imp_laser: 			out std_logic;
	      	imp_gen: 			out std_logic;
			sgn_up_delay:		in std_logic;			
			sgn_dwn_delay:		in std_logic;
			p_in_select_mode: 	in std_logic_vector (1 downto 0);			-- выбор режима работы 
		  																	-- 00 - генераторы выключен, работа от внешенего генератора импульсов
		  																	-- 01 - непрерывная генерация импульсов с частотой 100 Гц
		  																	-- 10 - генерация 64 импульсов в режиме пачек импульсов по 4 импульса в пачке
		  																	-- 11 - генерация 64 импульсов в режиме частоты импулсов 6 кГц
				p_out_strobe_end_test:	out std_logic;						-- генерация строба, сигнализииружщего о завершении прогона по всем кналам (выдачи 64 импульсов)
				p_end_pack:				out std_logic
						  );	
end gen;

architecture gen_synt of gen is
	shared variable change_delay_up:	integer range 0 to 63:=25;		
	shared variable change_delay_dwn:	integer range 0 to 63:=25;	
begin
	out_impulse:process(clk)
		variable v_counter: 								integer range 0 to 5010001;		-- счетчик тиков
		variable v_out_max_impulse_counter: 				integer range 0 to 64;			-- счетчик максимального количества импульсов 64
		variable v_flag_end_test:							std_logic:='0';
		variable v_reg_freq: 								integer range 0 to 5000000;		-- регистр частоты импульсов 
		variable v_count_delay_before_end_test_strobe: 		integer range 0 to 10:=10;		
	begin
		if rising_edge(clk) then

-- сброс генератора в исходное состояние по нажатию кнопки "ЗАПУСК"
			if p_in_rst='1' then
				v_counter:=0;
				v_out_max_impulse_counter:=0;
				v_flag_end_test:='0';
				v_count_delay_before_end_test_strobe:=10;
			end if;

-- формитрование строба окончания прогона блока при работе от внутреннего генератора в режиме прогона частот
			if v_flag_end_test='0' then
				p_out_strobe_end_test<='0';
			elsif v_flag_end_test='1' then

-- после того, как были сформированны 64 импульса и был выставлен флаг окончания работы генератора, ожидаем 200 тактов перед выставлением строба об окончании прогона
				if v_count_delay_before_end_test_strobe/=0 then
					v_count_delay_before_end_test_strobe:=v_count_delay_before_end_test_strobe-1;
					p_out_strobe_end_test<='0';
				elsif v_count_delay_before_end_test_strobe=0 then
					p_out_strobe_end_test<='1';
				end if;

			end if;

-- выбор значения частоты следования импульсов и часоты пачек между ними
			--if p_in_select_mode/="00" and v_flag_end_test='0' then
			if v_flag_end_test = '0' then
				if (p_in_select_mode="01" or p_in_select_mode = "00") then						-- режим прогона
					v_reg_freq:=c_base_work;
					p_end_pack<='0';
				elsif p_in_select_mode="10" and (v_out_max_impulse_counter mod 4)=0 then					-- режим работы пачками по 4 импульса
					v_reg_freq:=c_period_between_pack;
					p_end_pack<='1';
				elsif p_in_select_mode="10" and (v_out_max_impulse_counter mod 4)/=0 then
					v_reg_freq:=c_impulse_period;
					p_end_pack<='0';
			--	elsif p_in_select_mode="11" then					-- режим работы на частоте 6 кГц
			--		v_reg_freq:=c_freq_six_khz;
			--		p_end_pack<='0';
				end if;
-- подсчет тиков кварца 	 
				v_counter:=v_counter+1;		
--отрисовка пары импульсов (запуск генератора и запуск лазера) с заданной между ними задержкой						    																										
				if v_counter>0 and v_counter<v_reg_freq then																-- пауза перед передним фронтом
					imp_gen<='0';
					imp_laser<='1';
				elsif v_counter>v_reg_freq and v_counter<(c_length_impulse_gen + v_reg_freq) then							-- передний фронт первого ипульса
					imp_gen<='1';
					imp_laser<='1';
				elsif v_counter>(c_length_impulse_gen + v_reg_freq) and v_counter < (v_reg_freq + c_delay_laser_after_gen+(change_delay_dwn-change_delay_up)) then	-- задний фронт первого импульса
					imp_gen<='0';
					imp_laser<='1';
				elsif v_counter>(v_reg_freq + c_delay_laser_after_gen+(change_delay_dwn-change_delay_up)) and v_counter<(v_reg_freq + c_length_impulse_laser + c_delay_laser_after_gen+(change_delay_dwn-change_delay_up)) then	-- передний фронт второго импульса
					imp_gen<='0';
					imp_laser<='0';
				elsif v_counter>(v_reg_freq + c_length_impulse_laser + c_delay_laser_after_gen+(change_delay_dwn-change_delay_up)) then							-- задний фронт второго импульса
					imp_gen<='0';
					imp_laser<='1';

					if p_in_select_mode ="10" or p_in_select_mode = "00" then
						v_out_max_impulse_counter:=v_out_max_impulse_counter+1;
					end if;
					
					v_counter:=0;

					if (p_in_select_mode="10") and v_out_max_impulse_counter= 64 then  -- 64 отсчета (количество проверяемых каналов)
						v_flag_end_test:='1';
					elsif (p_in_select_mode="00") then--and v_out_max_impulse_counter = 1 then  -- 1 отсчет (количество проверяемых каналов)
						v_flag_end_test:='1';
					end if;
				end if;

			end if;
		end if;
	end process;
--/////////////////////////////////////////////////////////////////////////////	
-- уменьшение времени задержки
up_delay:process(sgn_up_delay)
		begin
			if sgn_up_delay'event and sgn_up_delay='1' then
				change_delay_up:=change_delay_up+1;
			end if;
	end process;
--/////////////////////////////////////////////////////////////////////////////
-- увеличение времени задержки		
dwn_delay:process(sgn_dwn_delay)
			begin
				if sgn_dwn_delay'event and sgn_dwn_delay='1' then
					change_delay_dwn:=change_delay_dwn+1;
				end if;
			end process;
			
--////////////////////////////////////////////////////////////////////////////				
end architecture;