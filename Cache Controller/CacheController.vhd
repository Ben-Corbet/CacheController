----------------------------------------------------------------------------------
-- Company: 
-- Engineer:
-- 
-- Create Date:    14:34:40 10/16/2025 
-- Design Name: 
-- Module Name:    CacheController - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CacheController is
    Port ( clk : in  STD_LOGIC;
           ADDR : out  STD_LOGIC_VECTOR (15 downto 0);
           DOUT : out  STD_LOGIC_VECTOR (7 downto 0);
           WR_RD : out  STD_LOGIC;
           MEMSTRB : out  STD_LOGIC;
           RDY : out  STD_LOGIC;
           CS : out  STD_LOGIC);
end CacheController;

architecture Behavioral of CacheController is

--- CPU Signals
	signal CPU_ADDR : STD_LOGIC_VECTOR (15 downto 0);
	signal CPU_Dout : STD_LOGIC_VECTOR(7 downto 0);
	signal CPU_Din : STD_LOGIC_VECTOR(7 downto 0);
	signal CPU_W_R : STD_LOGIC;
	signal CPU_CS : STD_LOGIC;
	signal CPU_RDY : STD_LOGIC;

	signal cpuTag : STD_LOGIC_VECTOR(7 downto 0);
	signal index : STD_LOGIC_VECTOR(2 downto 0);
	signal offset : STD_LOGIC_VECTOR(4 downto 0);
	
--- SRAM(Cache Memory) Signals
	signal Dbit : STD_LOGIC_VECTOR(7 downto 0):= "00000000";
	signal Vbit : STD_LOGIC_VECTOR(7 downto 0):= "00000000";
	signal SRAM_ADDR : STD_LOGIC_VECTOR(7 downto 0);
	signal SRAM_Din : STD_LOGIC_VECTOR(7 downto 0);
	signal SRAM_Dout : STD_LOGIC_VECTOR(7 downto 0);
	signal SRAM_Wen : STD_LOGIC_VECTOR(0 DOWNTO 0);
	
--SDRAM Signals
	signal SDRAM_ADDR	: STD_LOGIC_VECTOR(15 downto 0);
	signal SDRAM_Din : STD_LOGIC_VECTOR(7 downto 0);
	signal SDRAM_Dout : STD_LOGIC_VECTOR(7 downto 0);
	signal SDRAM_MEMSTRB : STD_LOGIC;
	signal SDRAM_W_R : STD_LOGIC;
	signal SDRAM_offset : integer := 0;
	signal SRAM_offset : integer := 0;

--- SDRAM MSTRB Counter
	signal counter : integer := 0;

--SRAM array
	type cacheControllerMemory is array (7 downto 0) of STD_LOGIC_VECTOR(7 downto 0);
	signal controllerTag: cacheControllerMemory := ((others=> (others=>'0')));


--- Store the last CPU_ADDRress
	signal prevCPUAddr : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');


--- Store a binary value for state in order to understand the the transitions
	signal state 					: STD_LOGIC_VECTOR(3 downto 0);
	
--- Use set state values for logic
	type state_value is (state0, state1, state2, state3, state4, state5, state6);
	signal state_current : state_value := state0;

--State Signals
	-- State0 = Ready
	-- State1 = Idle
	-- State2 = Hit
	-- State5 = Miss
	-- State = Compare TAG 
	-- State3 = Load From Memory
	-- State4 = Write Back To Memory

--- ICON & ILA Signals 
	signal control0 : STD_LOGIC_VECTOR(35 downto 0);
	signal ila_data : std_logic_vector(113 downto 0);
	signal trig0 : std_logic_vector(0 TO 0);
	signal reset : STD_LOGIC;
	
--- SDRAM Controller Component
	COMPONENT SDRAMController 
    Port ( 
		clk : in  STD_LOGIC;
		ADDR : in  STD_LOGIC_VECTOR (15 downto 0);
		Din : in  STD_LOGIC_VECTOR (7 downto 0);
      Dout : out STD_LOGIC_VECTOR (7 downto 0);
      wr_rd : in  STD_LOGIC;
      MEMSTRB : in  STD_LOGIC);
      
	END COMPONENT;

--- SRAM Component for Cache Memory
	COMPONENT BRAM
	PORT (
		clka : IN STD_LOGIC;
		wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
	END COMPONENT;
	
--- CPU Component
	COMPONENT CPU_gen 
	Port ( 
		clk : in  STD_LOGIC;
      rst : in  STD_LOGIC;
      trig : in  STD_LOGIC;
      Address : out STD_LOGIC_VECTOR (15 downto 0);
      wr_rd : out STD_LOGIC;
      cs : out STD_LOGIC;
      Dout : out STD_LOGIC_VECTOR (7 downto 0));
	END COMPONENT;	

--- ICON Component
	COMPONENT icon
	PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
	END COMPONENT;
	
--- ILA Component
	COMPONENT ila
	PORT (
		CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
		CLK : IN STD_LOGIC;
		DATA : IN STD_LOGIC_VECTOR(113 DOWNTO 0);
		TRIG0 : IN STD_LOGIC_VECTOR(0 TO 0));
	END COMPONENT;
	
begin

--PORT MAPS:
	myCPU_gen : CPU_gen Port Map (
					clk,
					reset,
					CPU_RDY,
					CPU_ADDR,
					CPU_W_R,
					CPU_CS,
					CPU_Dout
					);
	
	SDRAM : SDRAMController	Port Map (
					clk,
					SDRAM_ADDR,
					SDRAM_Din,
					SDRAM_Dout,
					SDRAM_W_R,
					SDRAM_MEMSTRB
					);

	mySRAM : BRAM Port Map (
					clk,
					SRAM_Wen,
					SRAM_ADDR,
					SRAM_Din,
					SRAM_Dout
					);

	myIcon : icon Port Map (
					CONTROL0
					);

	myILA : ila Port Map (
					CONTROL0,
					CLK,
					ila_data,
					TRIG0
					);
	
process(clk, CPU_CS)		
	begin
		if (rising_edge(clk)) then
			
			--- Initialize Signals For New Instruction
			if (state_current = state0) then
				CPU_RDY 	<= '0';
				if (CPU_CS = '1' AND prevCPUAddr /= CPU_ADDR) then
					prevCPUAddr <= CPU_ADDR;
					
					cpuTag <= CPU_ADDR(15 downto 8);
					index <= CPU_ADDR(7  downto 5);
					offset	<= CPU_ADDR(4  downto 0);
					
					SDRAM_ADDR(15 downto 5) <= CPU_ADDR(15 downto 5);
					SRAM_ADDR(7 downto 0) <= CPU_ADDR(7 downto 0);
					SRAM_Wen <= "0";

					--- Move to Tag Compare State
					state_current <= state6; 
					state  <= "0110";
					end if;


			elsif(state_current = state1) then
				--- Idle State
				CPU_RDY <= '1';
				if (CPU_CS = '1') then
				
					--- Got To Ready State
					state_current <= state0;
					state <= "0000";
				end if;


			elsif(state_current = state2) then 
				--- Perform Process State
				--- If a write command then write to SRAM
				--- CPU_DIN gets 0s input to specify write
				if (CPU_W_R = '1') then 
					SRAM_Wen <= "1";
					Dbit(to_integer(unsigned(index))) <= '1';
					Vbit(to_integer(unsigned(index))) <= '1';
					SRAM_Din <= CPU_Dout;
					CPU_Din <= "00000000";
				
				--- If a read command then read SRAM and pass to CPU_DIN
				else
					SRAM_Wen <= "0";
					CPU_Din <= SRAM_Dout;
				end if;
				
				--- Return to IDLE
				state_current <= state1;
				state <= "0001";


			elsif(state_current = state3) then 
				--- Load Block From SDRAM
				if (counter >= 65) then --- 32 words per block requires 64 clk cycles
					counter <= 0;
					Vbit(to_integer(unsigned(index))) <= '1';
					controllerTag(to_integer(unsigned(index))) <= cpuTag;
					SDRAM_offset <= 0;
					SRAM_offset <= 0;
					
					--- Restore SRAM Address
					SRAM_ADDR(7 downto 0) <= CPU_ADDR(7 downto 0);
					
					--- Perform CPU Process
					state_current <= state2;
					state <= "0010";

				else
					if (counter mod 2 = 1) then
						--- Strobe SDRAM
						SDRAM_MEMSTRB <= '0';
						SRAM_ADDR(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SRAM_offset, offset'length));
						SRAM_Din <= SDRAM_Dout;
						SRAM_Wen <= "1";
						SRAM_offset <= SRAM_offset + 1;
						
					else
						if (SDRAM_offset < 32) then
							SDRAM_ADDR(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SDRAM_offset, offset'length));
							SDRAM_W_R <= '0';
							SDRAM_MEMSTRB <= '1';
							SDRAM_offset <= SDRAM_offset + 1;
						else
							SDRAM_MEMSTRB <= '0';
						end if;
						SRAM_ADDR(7 downto 5) <= index;
						
					end if;

				--- Increment counter every clk cycle for SDRAM Strobe
				counter <= counter + 1;
				end if;		


			elsif(state_current = state4) then
				--- Write back to main memory
				if (counter >= 65) then
					counter <= 0;
					Dbit(to_integer(unsigned(index))) <= '0';
					SDRAM_offset <= 0;
					SRAM_offset <= 0;
					SDRAM_ADDR(15 downto 5) <= CPU_ADDR(15 downto 5);
					state_current <= state3;
					state <= "0011";
				else
					if (counter mod 2 = 1) then
						--- Strobe SDRAM
						SDRAM_MEMSTRB <= '0';
						if (SDRAM_offset < 32) then
							SRAM_ADDR(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SRAM_offset , offset'length));
							SRAM_ADDR(7 downto 5) <= index;
							SRAM_Wen <= "0";
							SRAM_offset <= SRAM_offset + 1;

						end if;
					else						
						if (counter > 1) then
							SDRAM_ADDR(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SDRAM_offset, offset'length));
							SDRAM_W_R <= '1';
							SDRAM_MEMSTRB <= '1';
							SDRAM_Din <= SRAM_Dout;	
							SDRAM_offset <= SDRAM_offset + 1;
						else
							SDRAM_MEMSTRB <= '0';

						end if;
					end if;
					--- Increment counter for SDRAM Strobe
					counter <= counter + 1;
				end if;

			elsif (state_current = state5) then
				--- Miss State
				if (Dbit(to_integer(unsigned(index))) = '1' AND Vbit(to_integer(unsigned(index))) = '1') then
					
					--- Write back updated block to SDRAM
					SDRAM_ADDR(15 downto 8) <= controllerTag(to_integer(unsigned(index))); 
					state_current <= state4; 
					state <= "0100";
				else
				
					--- Only Read From SDRAM
					state_current <= state3;
					state <= "0011";
				end if;

			elsif (state_current = state6) then
				--Evaluating a HIT/MISS
				if(Vbit(to_integer(unsigned(index))) = '1' AND controllerTag(to_integer(unsigned(index))) = cpuTag) then --- HIT
					
					--- Go to Hit State
					state_current <= state2;
					state <= "0010";

				else --- MISS
					
					--- Go to Miss State
					state_current <= state5; 
					state <= "0101";
				end if;
			end if;
		end if;
end process;
	
	MEMSTRB <= SDRAM_MEMSTRB;
	ADDR 	<= CPU_ADDR;
	WR_RD <= CPU_W_R;
	DOUT	<= CPU_Din;
	RDY	<= CPU_RDY;
	CS 	<= CPU_CS;

	
--- MAP ILA

	ila_data(15 downto 0) <= CPU_ADDR;
	--- TAG from CPU
	ila_data(23 downto 16) <= CPU_ADDR(15 downto 8);
	--- TAG from CACHE
	ila_data(31 downto 24) <= controllerTag(to_integer(unsigned(index)));
	ila_data(32) <= CPU_W_R;
	ila_data(33) <= CPU_RDY;
	ila_data(34) <= SDRAM_MEMSTRB;
	ila_data(38 downto 35) <= state;
	ila_data(46 downto 39) <= CPU_Din;
	ila_data(54 downto 47) <= CPU_Dout;
	ila_data(55) <= CPU_CS;
	ila_data(56) <= Vbit(to_integer(unsigned(index)));
	ila_data(57) <= Dbit(to_integer(unsigned(index)));
	ila_data(65 downto 58) <= SRAM_ADDR;
	ila_data(73 downto 66) <= SRAM_Din;
	ila_data(81 downto 74) <= SRAM_Dout;
	ila_data(97 downto 82) <= SDRAM_ADDR;
	ila_data(105 downto 98) <= SDRAM_Din;
	ila_data(113 downto 106) <= SDRAM_Dout;

	reset <= trig0(0);

end Behavioral;

