
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


entity in_out_elem_tb is
end in_out_elem_tb;


architecture in_out_elem_tb_arc of in_out_elem_tb is

	
	component in_out_elem is
		port (	p_i_clk:	in std_logic;
				p_i_imp:	in std_logic;
				p_o_imp:	out std_logic;
				p_i_mode:	in std_logic;
				p_i_rst:	in std_logic
		);
	end component;


	SIGNAL s_CLK, s_IN, s_OUT: std_logic;
	SIGNAL s_MODE, s_RST:	std_logic;
begin

	process begin
		s_CLK <= '1';
		wait for 1 ns;
		s_CLK <= '0';
		wait for 1 ns;
	end process;


	in_out_elem_module: in_out_elem port map (	p_i_clk => s_CLK,
												p_i_imp => s_IN,
												p_o_imp => s_OUT,
												p_i_mode => s_MODE,
												p_i_rst => s_RST
		);


	process begin
		s_IN <= '1';
		wait for 30 ns;
		s_IN <= '0';
		wait for 10 ns;
		s_IN <= '1';
		wait;
	end process;



	process begin
		s_MODE <= '1';
		wait;
	end process;

	process begin
		s_RST <= '0';
		wait for 80 ns;
		s_RST <= '1';
		wait for 5 ns;
		s_RST <= '0';
		wait;
	end process;


end in_out_elem_tb_arc;