
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;



entity stand_ki_v1 is
	port (


			p_CLK:			    in 	std_logic;
	
			--p_EXT_INP_PORT_VECTOR:	in std_logic_vector(63 downto 0);
			p_EXT_INP_PORT_VECTOR: inout std_logic_vector(63 downto 0);

			p_EXT_OUT_PORT_VECTOR:	out std_logic_vector(63 downto 0);

			p_EXT_CNTRL_BUTTON_OFF: 	in	std_logic;		
			p_EXT_CNTRL_BUTTON_CONT: 	in	std_logic;		
			p_EXT_CNTRL_BUTTON_FOUR: 	in std_logic;		
			p_EXT_CNTRL_BUTTON_RUN: 	in	std_logic;		
			p_EXT_GEN_BUTTON_UP:		in	std_logic;		
			p_EXT_GEN_BUTTON_DWN:		in	std_logic;		
			
			p_I_SEL_MODE:					in std_logic;
			
			
			
			p_EXT_IMP_LASER:			out std_logic;
			p_EXT_IMP_GEN:				out std_logic
					
);
end entity ; 



architecture dec_to_ram_tb_behav of stand_ki_v1 is

--	component fake_mem is
--	port (
--			clock		: IN STD_LOGIC ;
--			data		: IN STD_LOGIC_VECTOR (63 DOWNTO 0);
--			rdaddress	: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
--			rden		: IN STD_LOGIC  := '1';
--			wraddress	: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
--			wren		: IN STD_LOGIC  := '1';
--			q			: OUT STD_LOGIC_VECTOR (63 DOWNTO 0)
--	  ) ;
--	end component; -- fake_mem

--	component block_emul is
--	port (	p_i_clk:	in std_logic;
--			p_i_las: 	in std_logic;
--			p_i_gen:	in std_logic;
--			p_o_imp:	out std_logic
--			);
--	end component;

	component stand_test is
	port (	p_CLK:					in std_logic;
				p_i_RES:				in std_logic;
				p_IN_IMP_LAS:			in std_logic;								-- вход \ сигнал запуска лазера
				p_IN_IMP_GEN:			in std_logic;								-- вход \ сигнал запуска генератора
				p_OUT_IMP:				out std_logic_vector(63 downto 0)	-- выход \ имитация выхродного импульса блока по одному из каналов
			);
	end component;


	component mem1 IS
		PORT
		(
			clock		: IN STD_LOGIC ;
			data		: IN STD_LOGIC_VECTOR (63 DOWNTO 0);
			rdaddress	: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
			rden		: IN STD_LOGIC  := '1';
			wraddress	: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
			wren		: IN STD_LOGIC  := '1';
			q			: OUT STD_LOGIC_VECTOR (63 DOWNTO 0)
		);
	END component;

	component in_out_elem is
		port (	p_i_clk:	in std_logic;
				p_i_imp:	in std_logic;
				p_o_imp:	out std_logic;
				p_i_mode:	in std_logic;
				p_i_rst:	in std_logic
		);
	end component;



	component gen
	port (
			clk:					in std_logic;
			p_in_rst: 				in std_logic;
			imp_laser:				out std_logic;
			imp_gen:				out std_logic;
			sgn_up_delay:			in std_logic;
			sgn_dwn_delay:			in std_logic;
			p_in_select_mode: 		in std_logic_vector(1 downto 0);
			p_out_strobe_end_test: 	out std_logic;
			p_end_pack:				out std_logic
		);
	end component;

	
	component control_4 is
		port(
	 			p_i_clk:		in std_logic;
				p_i_btn_run:	in std_logic;
	  			p_i_rg_off:		in std_logic;
	  			p_i_rg_cont:	in std_logic;
	  			p_i_rg_pack:	in std_logic;
		
				p_o_gen_rst:	out std_logic; 		-- сигнал сброса генератора импульсов
				p_o_mode:		out std_logic_vector(1 downto 0); -- режим работы генератора импульсов
				p_i_gen_end_work: in std_logic;		-- сигнал окончания работы генератора импульсов в режиме пачки
				p_i_las_imp:	in std_logic; 		-- импульс запуска лезера

				p_o_addr: 		out std_logic_vector(5 downto 0);  -- адрес двойного слова в памяти куда будет проводиться чтение или запись
				p_o_rden:		out std_logic;
				p_o_wren: 		out std_logic;

				p_o_io_rst:		out std_logic;
				p_o_io_src:		out std_logic_vector (1 downto 0);
				p_o_io_dest:	out std_logic
			);
	end component ; -- control_4


	SIGNAL s_LAS_IMP, s_GEN_IMP: std_logic;
	SIGNAL s_MODE: std_logic_vector(1 downto 0);

	SIGNAL s_END_GEN, s_END_PACK_GEN: std_logic;
	SIGNAL s_IO_MODE, s_IO_RST: std_logic;

	SIGNAL s_IN_DATA, s_OUT_DATA: std_logic_vector(63 downto 0);

	SIGNAL s_EXT_INT_IMP_DATA: std_logic_vector (1 downto 0);
	SIGNAL s_EXT_INT_OUT_DATA: std_logic;

	SIGNAL s_MEM_OUT_DATA: std_logic_vector (63 downto 0);
	SIGNAL s_MEM_RDEN, s_MEM_WREN: std_logic;
	SIGNAL s_MEM_ADDR: std_logic_vector(5 downto 0);

	SIGNAL s_GEN_RST: std_logic;
	SIGNAL s_EXT_IN_DATA: std_logic_vector(63 downto 0);
	SIGNAL s_EMUL_OUT_DATA:	std_logic_vector(63 downto 0);



begin
	

	p_EXT_IMP_LASER <= s_LAS_IMP;
	p_EXT_IMP_GEN <= s_GEN_IMP;

	s_IO_MODE <= s_MODE(0) or s_MODE(1);
-- выбор источника данных для модулей приемопередатичков
-- 1 - источник данных - внешние входные порты
-- 0 - источник данных - выход памяти


	s_EXT_IN_DATA <= 	p_EXT_INP_PORT_VECTOR when p_I_SEL_MODE = '1' else
						s_EMUL_OUT_DATA;

	p_EXT_INP_PORT_VECTOR <= (others => 'Z') when p_I_SEL_MODE = '1' else
							s_EMUL_OUT_DATA;
							 

	s_IN_DATA <= 	s_EXT_IN_DATA when s_EXT_INT_IMP_DATA = "11" else --p_EXT_INP_PORT_VECTOR(63 downto 1) & s_IMP0 when s_EXT_INT_IMP_DATA = "11" else 
					s_MEM_OUT_DATA 			when s_EXT_INT_IMP_DATA = "01" else
					(others => '1');

	p_EXT_OUT_PORT_VECTOR <= s_OUT_DATA when s_EXT_INT_OUT_DATA ='1' else (others => '1');


	self_test_module: stand_test port map (
						p_CLK 			=> p_CLK,
						p_i_RES			=> s_GEN_RST,
						p_IN_IMP_LAS 	=> s_LAS_IMP,
						p_IN_IMP_GEN 	=> s_GEN_IMP,
						p_OUT_IMP 		=> s_EMUL_OUT_DATA
		);



	gen_module: gen 
	port map (
			clk 					=> p_CLK,
			p_in_rst 				=> s_GEN_RST,
			imp_laser 				=> s_LAS_IMP,
			imp_gen 				=> s_GEN_IMP,
			sgn_up_delay			=> p_EXT_GEN_BUTTON_UP,
			sgn_dwn_delay			=> p_EXT_GEN_BUTTON_DWN,
			p_in_select_mode 		=> s_MODE,
			p_out_strobe_end_test 	=> s_END_GEN,
			p_end_pack 				=> s_END_PACK_GEN
		);


	control_4_module: control_4 port map (
				p_i_clk			=> p_CLK,
				p_i_btn_run		=> p_EXT_CNTRL_BUTTON_RUN,
	  			p_i_rg_off 		=> p_EXT_CNTRL_BUTTON_OFF,--'0',--
	  			p_i_rg_cont 	=> p_EXT_CNTRL_BUTTON_CONT,--'0',--
	  			p_i_rg_pack		=> p_EXT_CNTRL_BUTTON_FOUR,--'1',--
		
				p_o_gen_rst 	=> s_GEN_RST,
				p_o_mode		=> s_MODE,
				p_i_gen_end_work => s_END_GEN,
				p_i_las_imp 	=> s_LAS_IMP,

				p_o_addr 		=> s_MEM_ADDR,
				p_o_rden		=> s_MEM_RDEN,
				p_o_wren		=> s_MEM_WREN,

				p_o_io_rst 		=> s_IO_RST,
				p_o_io_src		=> s_EXT_INT_IMP_DATA,
				p_o_io_dest 	=> s_EXT_INT_OUT_DATA
			);



	gen1: for i in 0 to 63 generate

		s_port_module: in_out_elem port map (	p_i_clk => p_CLK,	
												p_i_imp => s_IN_DATA(i),
												p_o_imp => s_OUT_DATA(i),
												p_i_mode => s_IO_MODE,
												p_i_rst => s_IO_RST
											);
	end generate;


	mem1_mod: mem1 port map(
--	mem1_mod:fake_mem port map(
			clock		=> p_CLK,
			data		=> s_OUT_DATA,
			rdaddress	=> s_MEM_ADDR,
			rden		=> s_MEM_RDEN,
			wraddress	=> s_MEM_ADDR,
			wren		=> s_MEM_WREN,
			q			=> s_MEM_OUT_DATA
		);

--	chan_emul: block_emul port map
--	(
--		p_i_clk		=> p_CLK,
--		p_i_las 	=> s_LAS_IMP,
--		p_i_gen 	=> s_GEN_IMP,
--		p_o_imp	 	=> s_IMP0
--		);

end architecture ; -- 