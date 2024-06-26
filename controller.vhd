library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity controller is
	port (
		clk : in std_logic;
		En : out std_logic;
		PMA : in std_logic_vector(13 downto 0); -- the PMA bus
		DMA : in std_logic_vector(13 downto 0); -- the DMA bus
		PMD : in std_logic_vector(23 downto 0); -- the PMD bus
		DMD : inout std_logic_vector(15 downto 0); -- the DMD bus
		s_shifter : out std_logic_vector(3 downto 0); -- selection signal for shifter muxes
		s_alu : out std_logic_vector(7 downto 0); -- selection signal for alu muxes
		s_mac : out std_logic_vector(10 downto 0); -- selection signal for mac muxes
		--s2_mac : out std_logic_vector(1 downto 0); -- selection signal for 4into1 mac mux
		s_program_seq : out std_logic_vector(1 downto 0); -- selection signal for program_control muxes				
		load_alu : out std_logic_vector(5 downto 0); -- load signal for alu registers
		load_mac : out std_logic_vector(7 downto 0); -- load signal for mac registers
		load_shifter : out std_logic_vector(2 downto 0); -- load signal for shifter registers
		load_program_seq : out std_logic; -- load signal for program control registers

		bc_shifter : out std_logic_vector(3 downto 0); -- shifter tristate buffers control signal
		bc_alu : out std_logic_vector(3 downto 0); -- alu tristate buffers control signal
		bc_mac : out std_logic_vector(5 downto 0); -- mac tristate buffers control signal
		bc_program_seq : out std_logic_vector(2 downto 0); -- program_control tristate buffers control signal

		pass : out std_logic; -- control bit for OR/PASS for shifter
		x_in : out std_logic; -- extension bit to be filled in the left part of shifter array
		HI_LO : out std_logic; -- control bit to indicate high/low position in shifter array
		offset : out std_logic_vector(7 downto 0); -- bits to indicate the offset for the shifter
		carry : out std_logic; -- carry out for ALU
		control : out std_logic_vector(4 downto 0); -- control code signal for alu and mac
		read : out std_logic -- signal for the memory 
	);
end controller;

architecture behav of controller is

	type state_type is (st1, st2);
	signal t_state : state_type := st2;

begin
	process (PMD)
		variable t_en : std_logic := '0';
		--variable t_s2_mac : std_logic_vector(1 downto 0) := "11";
		variable t_s_shifter : std_logic_vector(3 downto 0) := "0000"; -- selection signal for shifter muxes
		variable t_load_shifter : std_logic_vector(2 downto 0) := "000"; -- load signal for shifter registers
		variable t_s_program_seq : std_logic_vector(1 downto 0) := "00"; -- selection signal for proram_control muxes
		variable t_bc_shifter : std_logic_vector(3 downto 0) := "0000"; -- shifter tristate buffers control signal
		variable t_pass : std_logic := '1'; -- control bit for OR/PASS for shifter
		variable t_x_in : std_logic := '0'; -- extension bit to be filled in the left part of shifter array
		variable t_HI_LO : std_logic := '0'; -- control bit to indicate high/low position in shifter array
		variable t_offset : std_logic_vector(7 downto 0) := "00000000"; -- bits to indicate the offset for the shifter
		variable t_s_alu : std_logic_vector(7 downto 0) := "00000000"; -- selection signal for alu muxes
		variable t_s_mac : std_logic_vector(10 downto 0) := "00000000000"; -- selection signal for mac muxes
		variable t_load_alu : std_logic_vector(5 downto 0) := "000000"; -- load signal for alu registers
		variable t_load_mac : std_logic_vector(7 downto 0) := "00000000"; -- load signal for mac registers
		variable t_load_program_seq : std_logic := '0'; -- load signal for program control registers
		variable t_control : std_logic_vector(4 downto 0) := "00000"; -- control code signal for alu and mac
		variable t_bc_mac : std_logic_vector(5 downto 0) := "000000"; -- mac tristate buffers control signal
		variable t_bc_alu : std_logic_vector(3 downto 0) := "0000"; -- alu tristate buffers control signal
		variable t_bc_program_seq : std_logic_vector(2 downto 0) := "010"; -- program_control tristate buffers control signal
		variable t_carry : std_logic := '0';
		variable amf : integer := 0;
		variable temp : integer := 0;
		variable data : std_logic_vector(15 downto 0) := "0000000000000000";
		variable t_load : std_logic := '0';
		--t_state <= proc;

	begin
		t_en := '1';
		--t_s2_mac := "00";
		t_s_shifter := "0000"; -- selection signal for shifter muxes
		t_load_shifter := "000"; -- load signal for shifter registers
		t_s_program_seq := "00"; -- selection signal for proram_control muxes
		t_bc_shifter := "0000"; -- shifter tristate buffers control signal
		t_pass := '1'; -- control bit for OR/PASS for shifter
		t_x_in := '0'; -- extension bit to be filled in the left part of shifter array
		t_HI_LO := '0'; -- control bit to indicate high/low position in shifter array
		t_offset := "00000000"; -- bits to indicate the offset for the shifter
		t_s_alu := "00000000"; -- selection signal for alu muxes
		t_s_mac := "00000100100"; -- selection signal for mac muxes
		t_load_alu := "000000"; -- load signal for alu registers
		t_load_mac := "00000000"; -- load signal for mac registers
		t_load_program_seq := '0'; -- load signal for program control registers
		t_control := "00000"; -- control code signal for alu and mac
		t_bc_mac := "000000"; -- mac tristate buffers control signal
		t_bc_alu := "0000"; -- alu tristate buffers control signal
		t_bc_program_seq := "010"; -- program_control tristate buffers control signal
		t_carry := '0';
		amf := 0;
		temp := 0;
		data := "0000000000000000";
		t_load := '0';

		-- Load Data Register with Immediate data,  

		if (PMD(23 downto 20) = "0100") then
			t_state <= st2;
			DMD <= PMD(19 downto 4); -- Put the data on DMD bus

			-- select the data register
			case PMD(3 downto 0) is
				when "0000" => -- AX0
					t_load_alu(0) := '1';
				when "0001" => -- AX1
					t_load_alu(1) := '1';
					t_s_alu(1) := '1';
				when "0010" => -- MX0
					t_load_mac(0) := '1';
				when "0011" => -- MX1
					t_load_mac(1) := '1';
					t_s_mac(1) := '1';
				when "0100" => -- AY0
					t_load_alu(2) := '1';
				when "0101" => -- AY1
					t_load_alu(3) := '1';
					t_s_alu(2) := '1';
				when "0110" => -- MY0
					t_load_mac(2) := '1';
				when "0111" => -- MY1
					t_load_mac(3) := '1';
					t_s_mac(2) := '1';
				when "1000" => -- SI
					t_load_shifter(0) := '1';
				when "1010" => -- AR
					t_load_alu(4) := '1';
					t_s_alu(5) := '1';
				when "1011" => -- MR0
					t_load_mac(7) := '1';
					t_s_mac(7) := '1';
				when "1100" => -- MR1
					t_load_mac(6) := '1';
					t_s_mac(6) := '1';
				when "1101" => -- MR2
					t_load_mac(5) := '1';
					t_s_mac(5) := '1';
				when "1110" => -- SR0
					t_load_shifter(2) := '1';
					t_s_shifter(2) := '1';
				when "1111" => -- SR1
					t_load_shifter(1) := '1';
					t_s_shifter(1) := '1';
				when others => temp := 0;
			end case;

			-- ALU/MAC with Internal Data Register Move
		elsif (PMD(23 downto 19) = "00101") then
			t_state <= st2;
			amf := conv_integer(PMD(17 downto 13));
			if (amf >= 1) and (amf <= 15) then -- MAC

				-- check the Y Operand
				if (PMD(12 downto 11) = "00") then -- MY0
					t_s_mac(4) := '0';
					t_s_mac(6) := '0';
				elsif (PMD(12 downto 11) = "01") then -- MY1
					t_s_mac(5) := '1';
					t_s_mac(6) := '0';
				end if;
				-- check the X Operand
				if (PMD(10 downto 8) = "000") then -- MX0
					t_s_mac(1) := '0';
					t_s_mac(3) := '0';
				elsif (PMD(10 downto 8) = "001") then -- MX1
					t_s_mac(1) := '1';
					t_s_mac(3) := '0';
				end if;

				t_bc_mac := "100000";
			elsif (amf >= 16) and (amf <= 31) then -- ALU
				-- check the Y Operand
				if (PMD(12 downto 11) = "00") then -- AY0
					t_s_alu(4) := '0';
					t_s_alu(6) := '0';

				elsif (PMD(12 downto 11) = "01") then -- AY1
					t_s_alu(4) := '1';
					t_s_alu(6) := '0';

				end if;

				-- check the X Operand
				if (PMD(10 downto 8) = "000") then -- AX0
					t_s_alu(1) := '0';
					t_s_alu(3) := '0';
				elsif (PMD(10 downto 8) = "001") then -- AX1
					t_s_alu(1) := '1';
					t_s_alu(3) := '0';
				end if;
				t_bc_alu := "0010";
			end if;

			t_control := PMD(17 downto 13);
			-- check the destination Register
			case PMD(7 downto 4) is
				when "0000" => -- AX0
					t_load_alu(0) := '1';
				when "0001" => -- AX1
					t_load_alu(1) := '1';
				when "0010" => -- MX0
					t_load_mac(0) := '1';
				when "0011" => -- MX1
					t_load_mac(1) := '1';
				when "0100" => -- AY0
					t_load_alu(2) := '1';
					t_s_alu(2) := '1';
				when "0101" => -- AY1
					t_load_alu(3) := '1';
					t_s_alu(2) := '1';
				when "0110" => -- MY0
					t_load_mac(2) := '1';
					t_s_mac(2) := '1';
				when "0111" => -- MY1
					t_load_mac(3) := '1';
					t_s_mac(2) := '1';
				when "1010" => -- AR
					t_load_alu(4) := '1';
				when "1011" => -- MR0
					--t_load_mac(4) := '1';
					t_load_mac(7) := '1';
				when "1100" => -- MR1
					t_load_mac(5) := '1';
					t_s_mac(8) := '1';
				when "1101" => -- MR2
					t_load_mac(6) := '1';
					t_s_mac(9) := '1';
				when others => temp := 0;
			end case;

			-- check the source Register

			case PMD(3 downto 0) is
				when "0000" => -- AX0
					t_s_alu(1) := '0';
				when "0001" => -- AX1
					t_s_alu(1) := '1';
				when "0010" => -- MX0
					t_s_mac(1) := '0';
				when "0011" => -- MX1
					t_s_mac(1) := '1';
				when "0100" => -- AY0
					t_s_alu(4) := '0';
				when "0101" => -- AY1
					t_s_alu(4) := '1';
				when "0110" => -- MY0
					t_s_mac(4) := '0';
				when "0111" => -- MY1
					t_s_mac(4) := '1';
				when "1010" => -- AR
					t_bc_alu(3) := '1';
					t_s_alu(3) := '1';

				when "1011" => -- MR0
					t_bc_mac(3) := '1';
					t_s_mac(3) := '1';
				when "1100" => -- MR1
					t_bc_mac(4) := '1';
					t_s_mac(3) := '1';
				when "1101" => -- MR2
					t_bc_mac(5) := '1';
					t_s_mac(3) := '1';
				when others => temp := 0;
			end case;
			--end if;
			-- Immediate Shift

		elsif (PMD(23 downto 15) = "000011110") then
			t_state <= st2;
			-- check the SF type
			case PMD(14 downto 11) is
				when "0000" => t_HI_LO := '1'; -- L HI
					t_pass := '1';
					t_x_in := '0';
				when "0001" => t_HI_LO := '1'; -- L HI OR
					t_pass := '0';
					t_x_in := '0';
				when "0010" => t_HI_LO := '0'; -- L LO
					t_pass := '1';
					t_x_in := '0';
				when "0011" => t_HI_LO := '0'; -- L LO OR
					t_pass := '0';
					t_x_in := '0';
				when "0100" => t_HI_LO := '1'; -- A HI
					t_pass := '1';
					t_x_in := '1';
				when "0101" => t_HI_LO := '1'; -- A HI OR
					t_pass := '0';
					t_x_in := '1';
				when "0110" => t_HI_LO := '0'; -- A LO
					t_pass := '1';
					t_x_in := '0';
				when "0111" => t_HI_LO := '0'; -- A LO OR
					t_pass := '0';
					t_x_in := '0';
				when "1000" => t_HI_LO := '1'; -- L HI
					t_pass := '1';
					t_x_in := '0';
				when "1001" => t_HI_LO := '1'; -- L HI OR
					t_pass := '0';
					t_x_in := '0';
				when "1010" => t_HI_LO := '0'; -- L LO
					t_pass := '1';
					t_x_in := '0';
				when "1011" => t_HI_LO := '0'; -- L LO OR
					t_pass := '0';
					t_x_in := '0';
				when others => temp := 0;
			end case;
			t_offset := PMD(7 downto 0);
			t_load_shifter(2 downto 1) := "11";
			t_bc_shifter(2 downto 1) := "01";

		elsif (PMD(23 downto 0) = "000000101000000000000000") then
			t_state <= st1;
		else t_state <= st2;
		end if;

		case t_state is
			when st1 => t_en := '0';
				En <= t_en;
			when st2 =>
				t_en := '1';
				En <= t_en;
				--s2_mac <= t_s2_mac;
				s_alu <= t_s_alu;
				s_mac <= t_s_mac;
				s_program_seq <= t_s_program_seq;
				bc_mac <= t_bc_mac;
				bc_alu <= t_bc_alu;
				bc_program_seq <= t_bc_program_seq;
				load_alu <= t_load_alu;
				load_mac <= t_load_mac;
				load_program_seq <= t_load_program_seq;
				s_shifter <= t_s_shifter;
				load_shifter <= t_load_shifter;
				bc_shifter <= t_bc_shifter;
				pass <= t_pass;
				x_in <= t_x_in;
				HI_LO <= t_HI_LO;
				offset <= t_offset;
				carry <= t_carry;
				control <= t_control;
			when others => null;

				--DMD<= Data;
		end case;

	end process;

	process (PMA)

		variable t_read : std_logic;

	begin

		t_read := '1';
		read <= t_read;

	end process;
end behav;