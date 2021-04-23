library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


entity flx_mem_tb is
end entity ; -- dec_to_ram_tb


architecture dec_to_ram_tb_behav of flx_mem_tb is

	component flx_simple is
	port (
			p_CLK:			    in 	std_logic;
	
			p_EXT_INP_PORT_VECTOR:	in std_logic_vector(63 downto 0);

			p_EXT_OUT_PORT_VECTOR:	out std_logic_vector(63 downto 0);

			p_EXT_CNTRL_BUTTON_OFF: 	in	std_logic;		
			p_EXT_CNTRL_BUTTON_CONT: 	in	std_logic;		
			p_EXT_CNTRL_BUTTON_FOUR: 	in std_logic;		
			p_EXT_CNTRL_BUTTON_RUN: 	in	std_logic;		
			p_EXT_GEN_BUTTON_UP:		in	std_logic;		
			p_EXT_GEN_BUTTON_DWN:		in	std_logic;		
			
			p_EXT_IMP_LASER:			out std_logic;
			p_EXT_IMP_GEN:				out std_logic
			);
	end component ; -- dec_to_ram_tb

	component stand_test is
	port (		p_CLK:					in std_logic;
				p_IN_IMP_LAS:			in std_logic;								-- вход \ сигнал запуска лазера
				p_IN_IMP_GEN:			in std_logic;								-- вход \ сигнал запуска генератора
				p_OUT_IMP:				out std_logic_vector(63 downto 0)	-- выход \ имитация выхродного импульса блока по одному из каналов
			);
	end component;
		

	SIGNAL s_CLK:		std_logic;
	SIGNAL s_MODE:		std_logic_vector(2 downto 0);
	SIGNAL s_BTN:		std_logic;
	SIGNAL s_LAS:		std_logic;
	SIGNAL s_GEN:		std_logic;
	SIGNAL s_INP:		std_logic_vector(63 downto 0);
	SIGNAL s_INPn:		std_logic_vector(63 downto 0);
	SIGNAL s_OUT:		std_logic_vector(63 downto 0);
	SIGNAL s_BTN_UP:	std_logic;
	SIGNAL s_BTN_DWN:	std_logic;

begin

	s_BTN_DWN <= '0';
	s_BTN_UP <= '0';

	s_INPn <= not s_INP;

	process begin
			s_MODE <= "010";
			s_BTN <= '0';
			wait for 100 ns;
			s_BTN <= '1';
			wait for 20 ns;
			s_BTN <= '0';
			wait;
	end process;


	dec_to_ram_mod: flx_simple port map(	p_CLK 					=> s_CLK,
											p_EXT_INP_PORT_VECTOR 	=> s_INPn,
											p_EXT_OUT_PORT_VECTOR	=> s_OUT,
													
											p_EXT_CNTRL_BUTTON_OFF 	=> s_MODE(0),
											p_EXT_CNTRL_BUTTON_CONT => s_MODE(1),
											p_EXT_CNTRL_BUTTON_FOUR => s_MODE(2),
											
											p_EXT_CNTRL_BUTTON_RUN 	=> s_BTN,
											p_EXT_GEN_BUTTON_UP 	=> s_BTN_UP,
											p_EXT_GEN_BUTTON_DWN 	=> s_BTN_DWN,

											p_EXT_IMP_LASER 		=> s_LAS,
											p_EXT_IMP_GEN 			=> s_GEN
										);

	stand_test_module: stand_test port map(
									p_CLK 			=> s_CLK,
									p_IN_IMP_LAS 	=> s_LAS,
									p_IN_IMP_GEN 	=> s_GEN,
									p_OUT_IMP 		=> s_INP
 		);



	process begin
		s_CLK <= '1';
		wait for 1 ns;
		s_CLK <= '0';
		wait for 1 ns;
	end process;

	


	

end architecture ; -- arch