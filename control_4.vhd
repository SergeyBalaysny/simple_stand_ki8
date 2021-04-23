library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_4 is
	generic (
				constant c_imp_delay : integer :=   5000000;
				constant c_pack_delay : integer := 15000000;
				constant c_wren_delay : integer := 400;
				constant c_wren_len : integer := 420
		);

  port (	  	-- периферия
			p_i_clk:		in std_logic;
			p_i_btn_run:	in std_logic;
  			p_i_rg_off:		in std_logic;
  			p_i_rg_cont:	in std_logic;
  			p_i_rg_pack:	in std_logic;
	-- генератор
			p_o_gen_rst:	out std_logic; 		-- сигнал сброса генератора импульсов
			p_o_mode:		out std_logic_vector(1 downto 0); -- режим работы генератора импульсов
			p_i_gen_end_work: in std_logic;		-- сигнал окончания работы генератора импульсов в режиме пачки
			p_i_las_imp:	in std_logic; 		-- импульс запуска лезера

			p_o_addr: 		out std_logic_vector(5 downto 0);  -- адрес двойного слова в памяти куда будет проводиться чтение или запись
			p_o_rden:		out std_logic;
			p_o_wren: 		out std_logic;


			p_o_io_rst:		out std_logic;
			p_o_io_src:		out std_logic_vector(1 downto 0);
			p_o_io_dest:	out std_logic


	
  ) ;
end entity ; -- control_4

architecture  control_4_behav of control_4 is

	SIGNAL s_COUNT: 	integer range 0 to 10000100;
	SIGNAL s_PACK_COUNT: integer range 0 to 3 := 0;

	SIGNAL s_LASER_FILTER:	std_logic_vector(3 downto 0);
	SIGNAL s_BTN_RUN_FILTER: std_logic_vector(3 downto 0);
	SIGNAL s_RUN_BTN_FLAG: std_logic := '0';

	SIGNAL s_MODE:	std_logic_vector(1 downto 0):="00";

	type t_state is (st_idle, st_set_new_mode, st_continue, st_wait_las, st_delay_after_laser, st_check_end_pack, st_out_data, st_pack_delay, st_imp_delay);
	SIGNAL s_FSM: t_state;


	SIGNAL s_ADDR: std_logic_vector (5 downto 0) := "000000";
	SIGNAL s_RDEN: std_logic := '0';
	SIGNAL s_WREN: std_logic := '0';
	SIGNAL s_IO_RST: std_logic := '0';

begin

	process(p_i_clk) begin
		if rising_edge(p_i_clk) then


			s_BTN_RUN_FILTER <= p_i_btn_run & s_BTN_RUN_FILTER(3 downto 1);
			s_LASER_FILTER <= p_i_las_imp & s_LASER_FILTER(3 downto 1);

			p_o_addr <= s_ADDR;
			p_o_wren <= s_WREN;
			p_o_rden <= s_RDEN;
			p_o_io_rst <= s_IO_RST;


-- определение нажатия кнопки запуск
			if s_BTN_RUN_FILTER(0) = '1' and s_BTN_RUN_FILTER(1) = '0' then
				s_RUN_BTN_FLAG <= '1';
			end if;


			case s_FSM is
-- по нажатию кнопки запуска
					when st_idle =>	if s_RUN_BTN_FLAG = '1' then
									-- определение нового режима работы
										if p_i_rg_off = '1' and p_i_rg_pack = '0' and p_i_rg_cont = '0' then
											s_MODE <= "00";
										elsif p_i_rg_off = '0' and p_i_rg_pack = '0' and p_i_rg_cont = '1' then
											s_MODE <= "01";
										elsif p_i_rg_off = '0' and p_i_rg_pack = '1' and p_i_rg_cont = '0' then
											s_MODE <= "10";
										else
											s_MODE <= "00";
										end if;


										s_RUN_BTN_FLAG <= '0';

										s_FSM <= st_set_new_mode;
									else
										p_o_gen_rst <= '0';
										s_FSM <= st_continue;
									end if;
									s_IO_RST <= '0';

-- состояние установки нового режима работы
					when st_set_new_mode =>	p_o_mode <= s_MODE;
											p_o_gen_rst <= '1';
											s_IO_RST <= '0';
											s_FSM  <= st_idle;

-- состояние продолжения работы в текущем режиме работы
					when st_continue => if s_MODE(1) = '0'  then  -- если текущий режим "непр" или  "выкл", то просто продолжаем работать в этом режиме
											p_o_io_src <= "11"; 	  -- вход приемопередатчика - внешний порт
											p_o_io_dest <= '1';   -- выход приемопередатчика - внешний порт
											s_FSM <= st_idle;
										else 					  -- если тнеущий режим работы "ПАЧКА"

											p_o_io_src <= "11";		-- вход приемопередатчика - внешний порт
											p_o_io_dest <= '0';		-- выходные порты переключаются в высокий уровень
											s_FSM <= st_wait_las;
										end if;

-- ожидание импульса запуска лазера
					when st_wait_las => if s_LASER_FILTER = "0011" then		-- по появлению сигнала запуска лазера
											s_COUNT <= 0; 					-- сброс счетчика задержки
											s_WREN <= '0';					-- сброс сигнала записи в память
											s_FSM <= st_delay_after_laser;  -- переход к задержки после сигнала запуска лазера
										end if;

-- задержка времени от момента запуска лазера
					when st_delay_after_laser =>	s_COUNT <= s_COUNT + 1; -- ждем 300 тактов после сигнала запуска лазера (приемопередатчика при этом держат на линиях выхода информацию о появлении сигнала на входе)
													if s_COUNT >= c_wren_delay and s_COUNT < c_wren_len then	-- после 300 тактов формируем строб записи в пямять текущего состояния всхе 64 приемников входного сиганла
														s_WREN <= '1';
													elsif s_COUNT >= c_wren_len then  -- после 320 тиков снимаем сигнал записи 64 разрядного слова в память
														s_WREN <= '0';

														--s_IO_RST <= '1';
														s_COUNT <= 0;
														s_FSM <= st_check_end_pack; -- проверяем, не выставил ли генератор сигнал об окончании прогона последовательности из 4 импульсов
													end if;

-- проверка окончания работы в режиме "пачка"
					when st_check_end_pack => 	s_IO_RST <= '1';
												if p_i_gen_end_work = '1' then		-- выставлен сигнал окончания работав генератора
													s_ADDR <= (others => '0');
													s_RDEN <= '0';
													s_COUNT <= 0;
													s_PACK_COUNT <= 0;
													p_o_io_src <= "00";				-- вход приемропередатчика паререключаесм на выход из памяти
													p_o_io_dest <= '1';				-- выходные порты подключаются к приемопередатчику
													s_FSM <= st_out_data; 			-- переход к выдачи данных
												else								-- генератор еще не окончил работу
													s_ADDR <= s_ADDR + '1'; 		-- переход к следующему адресу в памяти
													s_FSM <= st_idle;
												end if;



-- после прогона окончания работвы генератора в режиме "пачка" переход в режим выдачи сигналов из памяти
					when st_out_data => s_COUNT <= s_COUNT + 1;
										s_RDEN <= '1'; 				-- формируем сигнал чтения из памяти
										s_IO_RST <= '0';
										if s_COUNT >= 10 then 		-- на выходе памяти выставлено состояние 64 входов по этому состоянию срабатывае приемопередатчик
											s_COUNT <= 0;
											s_RDEN <= '0';			-- сигнал на считывание снят
											p_o_io_src <= "01";
											if s_PACK_COUNT >= 3 then  -- если импульс кратен 4 (последний в пачке из четырех импульсов) - задержка перед считыванием следующего импульса - увеличена
												s_PACK_COUNT <= 0;
												s_FSM <= st_pack_delay;
											else
												s_PACK_COUNT <= s_PACK_COUNT + 1; -- если импульс очереденой в пачке из 4 - задержка между считываниями стандартная
												s_FSM <= st_imp_delay;
											end if;
											
										end if;	

				-- стандартная задержка между считванием импульсов
					when st_imp_delay =>	s_COUNT <= s_COUNT + 1; 
											if s_COUNT >= c_imp_delay then 			-- после задержки 
												s_COUNT <= 0;
												s_ADDR <= s_ADDR + '1'; 		-- переход к следующему адресу в памяти
												p_o_io_src <= "00";
												s_IO_RST <= '1';
												s_FSM <= st_out_data;			-- на выдачу нового вектопра состояний из памяти
											end if;
-- увеличенная задержка между пачками импульсов
					when st_pack_delay =>	s_COUNT <= s_COUNT + 1; 			-- перед переходом к сичтыванию следующего импульса задержка увеличена
											if s_COUNT >= c_pack_delay then 			-- после задержки
												s_COUNT <= 0;
												if s_ADDR = "111111" then      	-- если прочитано последенне слово состояний из памяти 
													s_ADDR <= "000000"; 		-- обнуляем адрес
													s_MODE <= "00"; 			-- переход в режим "выкл"
													s_RUN_BTN_FLAG <= '0'; 		-- выставление флага установки нового режима
													p_o_gen_rst <= '0';
													s_IO_RST <= '1';
													s_FSM <= st_set_new_mode; 
												else
													s_ADDR <= s_ADDR + '1'; 		-- если не последнее слов состояния
													p_o_io_src <= "00";
													s_IO_RST <= '1';
													s_FSM <= st_out_data; 		-- переход к считыванию следующего слова состояний из памяти
												end if;
											end if;



														


									
										
									

													 	 
					when others => s_FSM <= st_idle;

			end case;


		end if;
	end process;


end architecture ; --  