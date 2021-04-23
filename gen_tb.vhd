library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity gen_tb is
end gen_tb;

architecture gen_tb_synt of gen_tb is
	SIGNAL s_CLK:			std_logic:='1';
	SIGNAL s_LASER_OUT:		std_logic:='1';
	SIGNAL s_GEN_OUT:		std_logic:='1';
	SIGNAL s_UP_DELAY:		std_logic:='0';
	SIGNAL s_DWN_DELAY:		std_logic:='0';
	SIGNAL s_IN_MODE: 		std_logic_vector(1 downto 0):="00";
	SIGNAL s_IN_RESET: 		std_logic:='1';
	SIGNAL s_OUT_END_TEST: 	std_logic:='0';
	SIGNAL s_END_PACK:		std_logic;


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

	begin
		gen_imp: gen port map (	s_CLK, 
								s_IN_RESET,
								s_LASER_OUT, 
								s_GEN_OUT,
								s_UP_DELAY,
								s_DWN_DELAY,
								s_IN_MODE,
								s_OUT_END_TEST,
								s_END_PACK
								);
		
		process
		begin
			s_CLK<='0';
			wait for 1 ns;		
			s_CLK<='1';
			wait for 1 ns;
		end process;


		process
		begin
			s_UP_DELAY<='0';
			wait for 100 ns;
			s_UP_DELAY<='0';
			wait for 100 ns;
			
		end process;


		process
		begin
			s_IN_RESET <= '0';
			wait for 300 ns;
			s_IN_RESET<='1';
			wait for 10 ns;
			s_IN_RESET<='0';
			wait;
			
		end process;

		process
		begin
			--s_IN_MODE<="01";
			--wait for 10000 ns;
			s_IN_MODE<="10";
			
			--s_IN_MODE<="11";
			--wait for 10000 ns;
			--s_IN_MODE<="00";
			wait;
		end process;

end architecture;