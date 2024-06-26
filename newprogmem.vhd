library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


Entity newProgramMem is
	port(	address: in integer;
		instr: out std_logic_vector(23 downto 0);
		read: in std_logic
	);
end newProgramMem;

Architecture behav of newProgramMem is

type data is array(0 to 12) of std_logic_vector(23 downto 0);
signal memory: data;

Begin
	memory(0) <= "000000000000000000000000";
	memory(1) <= "010000000000000000100000";
	memory(2) <= "010000000000000000110101";
	memory(3) <= "010000000000000001000010";
	memory(4) <= "010000000000000000100111";
	memory(5) <= "001001100010100000001111";
	memory(6) <= "001010100110100010100000";
	memory(7) <= "001010000010100010110000";
	memory(8) <= "000101000000000010110001";
	memory(9) <= "001001100011000000001111";
	memory(10) <= "001001100011000000001111";
	memory(11) <= "001001100011000000001111";
	memory(12) <= "000000000000000000000000";
	

process(read)
	begin
		if(read = '1')then
			instr <= "000000000000000000000000";
		else
			instr <= memory(address);
		end if;
end process;

End behav;
