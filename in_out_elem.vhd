
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity in_out_elem is
	generic(c_lem_imp: integer := 4500000);
	port (	p_i_clk:	in std_logic;
			p_i_imp:	in std_logic;
			p_o_imp:	out std_logic;
			p_i_mode:	in std_logic;
			p_i_rst:	in std_logic
		);
end in_out_elem;


architecture in_out_elem_behav of in_out_elem is

	SIGNAL s_COUT: integer := 0;
	SIGNAL s_IN_IMP_FILTER: std_logic_vector(3 downto 0);

begin

	process(p_i_clk) begin
		if rising_edge(p_i_clk) then

			s_IN_IMP_FILTER <= s_IN_IMP_FILTER (2 downto 0) & p_i_imp;

			if p_i_rst = '1' then
				s_COUT <= 0;
				p_o_imp <= '1';
			else

				if p_i_mode = '0' then
					p_o_imp <= p_i_imp;
					s_COUT <= 0;
				else
					if s_IN_IMP_FILTER = "1100" then
					--if p_i_imp = '0' then
						s_COUT <= c_lem_imp;
					end if;

					if s_COUT /= 0 then
						p_o_imp <= '0';
						s_COUT <= s_COUT - 1;
					else
						p_o_imp <= '1';
					end if;
				end if;

				
			end if;



		end if;
	end process;


end in_out_elem_behav;
