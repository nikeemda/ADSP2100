library ieee;
use ieee.std_logic_1164.all;

entity processing_unit is

	port (
		clk : in std_logic;
		rs, En : in std_logic;
		PMA : inout std_logic_vector(13 downto 0); -- the PMA bus
		DMA : inout std_logic_vector(13 downto 0); -- the DMA bus
		PMD : in std_logic_vector(23 downto 0); -- the PMD bus
		DMD : inout std_logic_vector(15 downto 0); -- the DMD bus
		R : inout std_logic_vector(15 downto 0);

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
end processing_unit;

architecture struct of processing_unit is
	component ALUTop is
		port (
			CLK : in std_logic;
			Load : in std_logic_vector(5 downto 0);
			Sel : in std_logic_vector(7 downto 0);
			DMD : inout std_logic_vector (15 downto 0);
			R : inout std_logic_vector(15 downto 0);
			PMD : in std_logic_vector(23 downto 0);
			AMF : in std_logic_vector(4 downto 0);
			CI : in std_logic;
			En : in std_logic_vector(3 downto 0);
			AZ, AN, AC, AV, AS : out std_logic;
			alu_out : inout std_logic_vector(15 downto 0));
	end component;

	component MACTop is
		port (
			clk : in std_logic;
			Load : in std_logic_vector(7 downto 0);
			Sel : in std_logic_vector(10 downto 0);
			DMD : inout std_logic_vector(15 downto 0);
			R : inout std_logic_vector(15 downto 0);
			PMD : in std_logic_vector(23 downto 0);
			En : in std_logic_vector(5 downto 0);
			AMF : in std_logic_vector(4 downto 0);
			MV : out std_logic;
			mac_out : inout std_logic_vector (15 downto 0)
		);
	end component;

	component BarrelShifter is
		port (
			clk : in std_logic; -- the clock
			pass : in std_logic; -- control bit for OR/PASS
			x_in : in std_logic; -- extension bit to be filled in the left part of shifter array
			HI_LO : in std_logic; -- control bit to indicate high/low position in shifter array
			rl : in std_logic_vector(2 downto 0); -- register loading enable bits
			sel : in std_logic_vector(3 downto 0); -- selecting bits for mux
			c : in std_logic_vector(7 downto 0); -- bits to indicate the offset
			ctr : in std_logic_vector(3 downto 0); -- tristate enable bits
			SR_out : inout std_logic_vector(31 downto 0);
			DMD : inout std_logic_vector(15 downto 0); -- the DMD bus
			R : inout std_logic_vector(15 downto 0) -- the R bus
		);
	end component;
	component PSTop is
		port (
			DMD : inout std_logic_vector(15 downto 0);
			Inst : in std_logic_vector(23 downto 0);
			ASTAT : in std_logic_vector(7 downto 0);
			Sel : in std_logic_vector(1 downto 0);
			CLK : in std_logic;
			Load : in std_logic; 
			Reset : in std_logic;
			En : in std_logic;
			TSB_Ctr : in std_logic_vector(2 downto 0);
			PMA : inout std_logic_vector(13 downto 0);
			PMD : in std_logic_vector(23 downto 0);
			CC : in std_logic_vector(3 downto 0);
			AddJump : in std_logic_vector(13 downto 0);
			AddTC : in std_logic_vector(17 downto 0);
			IRAddress : in std_logic_vector(13 downto 0)
		);
	end component;

	signal SS, MV, AQ, AS, AC, AV, AN, AZ : std_logic;
	--signal 	R: std_logic_vector(15 downto 0);
	signal Inst : std_logic_vector(23 downto 0);
	signal astat : std_logic_vector(7 downto 0);
	signal AddJump : std_logic_vector(13 downto 0);
	signal AddTC : std_logic_vector(17 downto 0);
	signal IRAddress : std_logic_vector(13 downto 0);
	signal CC : std_logic_vector(3 downto 0);
begin
	astat(0) <= AZ;
	astat(1) <= AN;
	astat(2) <= AV;
	astat(3) <= AC;
	astat(4) <= AS;
	astat(5) <= AQ;
	astat(6) <= MV;
	astat(7) <= SS;

	P1 : PSTop port map(
		DMD, Inst, astat, s_program_seq, clk, load_program_seq, rs, En, bc_program_seq,
		PMA, PMD, CC, AddJump, AddTC, IRAddress);
	A1 : ALUTop port map(clk, load_alu, s_alu, DMD, R, PMD, control, carry, bc_alu, AZ, AN, AV, AC, AS, alu_out);
	M1 : MACTop port map(clk, load_mac, s_mac, DMD, R, PMD, bc_mac, control, MV, mac_out);
	S1 : BarrelShifter port map(clk, pass, x_in, HI_LO, load_shifter, s_shifter, offset, bc_shifter, SR_out, DMD, R);

end struct;
	   
	   