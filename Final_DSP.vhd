library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Final_DSP is

	port (
		clk : in std_logic;
		rs : in std_logic;

		alu_out : inout std_logic_vector(15 downto 0);
		mac_out : inout std_logic_vector(15 downto 0);
		SR_out : inout std_logic_vector(31 downto 0)
	);

end Final_DSP;
architecture struct of Final_DSP is

	component processing_unit is
		port (
			clk : in std_logic;
			rs, En : in std_logic;
			PMA : inout std_logic_vector(13 downto 0); -- the PMA bus
			DMA : inout std_logic_vector(13 downto 0); -- the DMA bus
			PMD : in std_logic_vector(23 downto 0); -- the PMD bus
			DMD, R : inout std_logic_vector(15 downto 0);
			s_program_seq : in std_logic_vector(1 downto 0); -- selection signal for program_control muxes
			s_alu : in std_logic_vector(7 downto 0); -- selection signal for alu muxes
			s_mac : in std_logic_vector(10 downto 0); -- selection signal for mac muxes
			--s2_mac : in std_logic_vector(1 downto 0); -- selection signal for 4into1 mac mux			
			s_shifter : in std_logic_vector(3 downto 0); -- selection signal for shifter muxes

			load_program_seq : in std_logic; -- load signal for program control registers
			load_alu : in std_logic_vector(5 downto 0); -- load signal for alu registers
			load_mac : in std_logic_vector(7 downto 0); -- load signal for mac registers
			load_shifter : in std_logic_vector(2 downto 0); -- load signal for shifter registers
			bc_program_seq : in std_logic_vector(2 downto 0); -- program_control tristate buffers control signal
			bc_alu : in std_logic_vector(3 downto 0); -- alu tristate buffers control signal
			bc_mac : in std_logic_vector(5 downto 0); -- mac tristate buffers control signal
			bc_shifter : in std_logic_vector(3 downto 0); -- shifter tristate buffers control signal

			control : in std_logic_vector(4 downto 0); -- control code signal for alu and mac
			carry : in std_logic; -- carry signal for alu

			pass : in std_logic; -- control bit for OR/PASS for shifter
			x_in : in std_logic; -- extension bit to be filled in the left part of shifter array
			HI_LO : in std_logic; -- control bit to indicate high/low position in shifter array
			offset : in std_logic_vector(7 downto 0); -- bits to indicate the offset for the shifter
			alu_out : inout std_logic_vector(15 downto 0);
			mac_out : inout std_logic_vector(15 downto 0);
			SR_out : inout std_logic_vector(31 downto 0)
		);
	end component;

	component controller is
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
			read : out std_logic);
	end component;

	component newProgramMem is
		port(	address: in integer; --PMA
			instr: out std_logic_vector(23 downto 0); --PMD
			read: in std_logic
	);
	end component;
	signal PMA, DMA : std_logic_vector(13 downto 0);
	signal PMD : std_logic_vector(23 downto 0);
	signal DMD, R : std_logic_vector(15 downto 0);
	signal En : std_logic;
	signal s_program_seq : std_logic_vector(1 downto 0); -- selection signal for program_sequencer muxes
	signal s_alu : std_logic_vector(7 downto 0); -- selection signal for alu muxes
	signal s_mac : std_logic_vector(10 downto 0); -- selection signal for mac muxes
	signal s2_mac : std_logic_vector(1 downto 0); -- selection signal for 4into1 mac mux			
	signal s_shifter : std_logic_vector(3 downto 0); -- selection signal for shifter muxes

	signal load_program_seq : std_logic; -- load signal for program sequencer registers
	signal load_alu : std_logic_vector(5 downto 0); -- load signal for alu registers
	signal load_mac : std_logic_vector(7 downto 0); -- load signal for mac registers
	signal load_shifter : std_logic_vector(2 downto 0); -- load signal for shifter registers
	signal bc_program_seq : std_logic_vector(2 downto 0); -- program_control tristate buffers control signal
	signal bc_alu : std_logic_vector(3 downto 0); -- alu tristate buffers control signal
	signal bc_mac : std_logic_vector(5 downto 0); -- mac tristate buffers control signal
	signal bc_shifter : std_logic_vector(3 downto 0); -- shifter tristate buffers control signal
	signal control : std_logic_vector(4 downto 0); -- control code signal for alu and mac
	signal carry : std_logic; -- carry signal for alu

	signal pass : std_logic; -- control bit for OR/PASS for shifter
	signal x_in : std_logic; -- extension bit to be filled in the left part of shifter array
	signal HI_LO : std_logic; -- control bit to indicate high/low position in shifter array
	signal offset : std_logic_vector(7 downto 0); -- bits to indicate the offset for the shifter
	signal read : std_logic;
	signal pmaint: integer:= 0;
	
begin
	pmaint <= to_integer(unsigned(PMA));
	P1 : processing_unit port map(
		clk, rs, En, PMA, DMA, PMD, DMD, R, s_program_seq, s_alu, s_mac, s_shifter,
		load_program_seq, load_alu, load_mac, load_shifter, bc_program_seq, bc_alu, bc_mac, bc_shifter, control, carry,
		pass, x_in, HI_LO, offset, alu_out, mac_out, SR_out);
	PM1 : newProgramMem port map(pmaint, PMD, read);
	C1 : controller port map(
		clk, En, PMA, DMA, PMD, DMD, s_shifter, s_alu, s_mac, s_program_seq, load_alu, load_mac,
		load_shifter, load_program_seq, bc_shifter, bc_alu, bc_mac, bc_program_seq, pass, x_in, HI_LO,
		offset, carry, control, read);
	--PMD <=PMD_O;

end struct;
	  
	      
	      