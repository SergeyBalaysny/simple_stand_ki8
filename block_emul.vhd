
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


entity block_emul is
	port (	p_i_clk:	in std_logic;
			p_i_las: 	in std_logic;
			p_i_gen:	in std_logic;
			p_o_imp:	out std_logic
			);
end entity;

architecture block_emul_behav of block_emul is

	SIGNAL s_COUNT: integer := 0;
	SIGNAL s_LAS_FILTER: std_logic_vector(3 downto 0);
	SIGNAL s_GEN_FILTER: std_logic_vector(3 downto 0);

	type t_state is (st_wait_gen, st_wait_las, st_imp_out, st_delay);
	SIGNAL s_FSM: t_state;

	SIGNAL s_OUT_SGN: std_logic := '1';

begin

	process(p_i_clk) begin

		p_o_imp <= s_OUT_SGN;

		if rising_edge(p_i_clk) then

			s_LAS_FILTER  <= s_LAS_FILTER(2 downto 0) & p_i_las;
			s_GEN_FILTER  <= s_GEN_FILTER(2 downto 0) & p_i_gen;

			case s_FSM is

				when st_wait_gen =>	if s_GEN_FILTER = "0011" then 
										s_FSM <= st_wait_las;
									end if;

				when st_wait_las => if s_LAS_FILTER = "1100" then
										s_COUNT <= 0;
										s_FSM <= st_imp_out;
									end if;
				
				when st_imp_out => 	s_COUNT <= s_COUNT + 1;
									if s_COUNT >= 100 then
										s_COUNT <= 0;
										s_OUT_SGN <= '0';
										s_FSM <= st_delay;
									end if;

				when st_delay 	=>	s_COUNT <= s_COUNT + 1;
									if s_COUNT >= 100 then 
										s_COUNT <= 0;
										s_OUT_SGN <= '1';
										s_FSM <= st_wait_gen;
									end if;

				when others 	=> s_FSM <= st_wait_gen;

			end case;

		end if;

	end process;



end block_emul_behav;