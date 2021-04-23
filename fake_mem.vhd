library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fake_mem is
  port (
			clock		: IN STD_LOGIC ;
			data		: IN STD_LOGIC_VECTOR (63 DOWNTO 0);
			rdaddress	: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
			rden		: IN STD_LOGIC  := '1';
			wraddress	: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
			wren		: IN STD_LOGIC  := '1';
			q			: OUT STD_LOGIC_VECTOR (63 DOWNTO 0)
  ) ;
end entity ; -- fake_mem


architecture fake_mem_behav of fake_mem is


	type t_mem is array (63 downto 0) of std_logic_vector (63 downto 0);
	SIGNAL s_MEM: t_mem;

begin
	process(clock) begin
		if rising_edge(clock) then
			if rden = '1' then --s_RD_FILTER(0) = '0' and s_RD_FILTER(1) = '1' then
				
				q <= s_MEM(to_integer(IEEE.NUMERIC_STD.unsigned(rdaddress)));

			elsif wren = '1' then --s_WR_FILTER(0) = '0' and s_WR_FILTER(1) = '1' then
				
				s_MEM(to_integer(IEEE.NUMERIC_STD.unsigned(wraddress))) <= data;

			end if;

		end if;
	end process;



end architecture ; -- 