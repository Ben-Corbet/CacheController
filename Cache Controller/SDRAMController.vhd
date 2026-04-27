----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:39:45 10/16/2025 
-- Design Name: 
-- Module Name:    SDRAMController - Behavioral 
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

entity SDRAMController is
    Port ( 
			clk : in  STD_LOGIC;
			ADDR : in  STD_LOGIC_VECTOR (15 downto 0);
			Din : in  STD_LOGIC_VECTOR (7 downto 0);
         Dout : out  STD_LOGIC_VECTOR (7 downto 0);
         wr_rd : in  STD_LOGIC;
         MEMSTRB : in  STD_LOGIC
			);
end SDRAMController;

architecture Behavioral of SDRAMController is
    
	 --- Map full 16-bit address: row = ADDR(15 downto 5), col = ADDR(4 downto 0)
	 --- That gives 2048 rows x 32 columns = 65536 bytes
	 ---type sdrammemory is array (2047 downto 0, 31 downto 0) of std_logic_vector(7 downto 0);
	 ---signal SDRAM_SIGNAL: sdrammemory;
	 signal init : integer := 0;
	 
	 -- Reduced Map to speed synthesis: row = TAG[15:12]
	 type sdrammemory is array (15 downto 0, 31 downto 0) of std_logic_vector(7 downto 0);
	 signal SDRAM_SIGNAL: sdrammemory;
	
begin

process (clk)
    begin
        if rising_edge(clk) then	
            --- This resets the SDRAM
				if init = 0 then
					for I in 0 to 15 loop
						for J in 0 to 31 loop
							SDRAM_SIGNAL(i,j) <= "11111111";
						end loop;
					end loop;
					init <= 1;	
				end if;
				
				if MEMSTRB = '1' then
					if wr_rd = '1' then
						SDRAM_SIGNAL(to_integer(unsigned(ADDR(15 downto 12))),to_integer(unsigned(ADDR(4 downto 0)))) <= Din;    
               ELSE
						Dout <= SDRAM_SIGNAL(to_integer(unsigned(ADDR(15 downto 12))),to_integer(unsigned(ADDR(4 downto 0))));
					end if;
				end if;
        end if;
    end process;

end Behavioral;

