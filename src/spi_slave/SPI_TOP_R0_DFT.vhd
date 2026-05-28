----------------------------------------------------------------------------------
--////////////////////////////////////////////////////////////////////////////////
-- Company:				SKAIChips, Suwon, South Korea 
-- Engineer: 			Y.S.Song
-- Create Date:    	2024.03.
-- Design Name:	  	SPI_TOP_R0
-- Module Name:    	SPI_TOP_R0 
-- File Name:      	SPI_TOP_R0.vhd 
-- Block Name: 		SPI Slave Core	
-- Comments: 
--
--////////////////////////////////////////////////////////////////////////////////
--================================================================================
library IEEE;
   use IEEE.std_logic_1164.all;
   use IEEE.std_logic_misc.all;
   use IEEE.std_logic_arith.all;
   use IEEE.std_logic_unsigned.all;
--   library SYNOPSYS;
--   use synopsys.cyclone.all;
--   use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

----------------------------------------------------------------------------------
--================================================================================ 
entity SPI_TOP_R0_DFT is
----------------------------------------------------------------------------------
	generic (
		RWMEM_D	: integer := 16;
		ROMEM_D	: integer := 16;
		BITS_NUM: integer := 16
	);
	port	(
				RST			: in std_logic;	-- Active High Reset
				RW_FLAG		: in std_logic;	-- Active High Reset

				CSN			: in std_logic;   -- Active Low Chip Select
				SCLK		: in std_logic;	-- SPI Serial Clock ~10 MHz
				MOSI		: in std_logic;   -- Master Out Serial In
				MISO		: out std_logic;  -- Master In Serial Out
				MISO_OE		: out std_logic;  -- Master In Serial Out Enable

				SCLK_INV	: in std_logic;	-- SPI Serial Clocl Inversion
				RST_OR		: in std_logic;	-- RST=1 or CSN=1

    			INIT_WREG 	: in std_logic_vector(RWMEM_D*BITS_NUM-1 downto 0);
				WREG	    : out std_logic_vector (RWMEM_D*BITS_NUM-1 downto 0);
				RREG	    : in std_logic_vector (ROMEM_D*BITS_NUM-1 downto 0)
			);
end SPI_TOP_R0_DFT;
----------------------------------------------------------------------------------

--------------------------------------------------------------------  
--------------------------------------------------------------------  
architecture Behavioral of SPI_TOP_R0_DFT is
-------------------------------------------------------------------- 
	FUNCTION conv_integer1(S : STD_LOGIC_VECTOR) RETURN INTEGER IS
		VARIABLE result : INTEGER := 0;
	BEGIN
		FOR i IN S'RANGE LOOP
			IF S(i) = '1' THEN
				result := result + (2**i);
			ELSIF S(i) = '0' THEN
				result := result;
			ELSE
				result := 0;
			END IF;
		END LOOP;
		RETURN result;
	END conv_integer1;

	type rwmem_array_type is array (RWMEM_D-1 downto 0) of std_logic_vector(BITS_NUM-1 downto 0);
	type romem_array_type is array (ROMEM_D-1 downto 0) of std_logic_vector(BITS_NUM-1 downto 0);

	signal rwmem_array: rwmem_array_type;
	signal romem_array: romem_array_type;

	signal miso_reg		: std_logic;
	signal read_rw			: std_logic;
	signal read_cnt		: std_logic_vector(4 downto 0);
	signal read_addr		: std_logic_vector(6 downto 0);
	signal read_reg		: std_logic_vector(BITS_NUM-1 downto 0);
	signal read_shift_reg: std_logic_vector(BITS_NUM-2 downto 0);

	signal write_rw	: std_logic;
	signal write_addr	: std_logic_vector(6 downto 0);
	signal write_data	: std_logic_vector(BITS_NUM-1 downto 0);
	signal write_reg	: std_logic_vector(1+7+BITS_NUM-1 downto 0); -- (r/w + addr + BIT_NUM)-1
	
--------------------------------------------------------------------
begin
--------------------------------------------------------------------

--------------------------------------------------------------------

--__________________________________________________________________
--==================================================================
-- Register Read Operation
--==================================================================
--------------------------------------------------------------------
	process (SCLK, RST_OR) begin	
		if(RST_OR = '1') then		
			read_cnt <= "00000";
		elsif(SCLK'event and SCLK = '1') then
			read_cnt <= read_cnt + "00001";
		end if;
	end process;
--------------------------------------------------------------------
	process (SCLK, RST_OR) begin	
		if(RST_OR = '1') then		
			read_rw <= '1';
			read_addr <= "0000000";
			
		elsif(SCLK'event and SCLK = '1') then
			if(read_cnt = "00000") then
				read_rw <= MOSI;
				read_addr <= read_addr;
			elsif(read_cnt <= "00111") then
				read_rw <= read_rw;
				read_addr <= read_addr(5 downto 0) & MOSI;
			end if;
		end if;
	end process;
--------------------------------------------------------------------
	process (read_addr, romem_array, rwmem_array, RW_FLAG) begin				
		if(RW_FLAG = '0') then		
				read_reg <= romem_array(0);
		else
			if(read_addr >= RWMEM_D) then 
				read_reg <= romem_array(conv_integer1(read_addr-RWMEM_D));
			else
				read_reg <= rwmem_array(conv_integer1(read_addr));
			end if;
		end if;
	end process;
--------------------------------------------------------------------
	process (SCLK_INV, RST_OR, read_reg, RW_FLAG) begin	
		if(RST_OR = '1') then		
			if(RW_FLAG = '0') then
				read_shift_reg <= read_reg(14 downto 0);
				miso_reg <= read_reg(15);	
			else
				read_shift_reg <= (others => '0');
				miso_reg <= '0';
			end if;
		elsif(SCLK_INV'event and SCLK_INV = '1') then
			if(RW_FLAG = '0') then
				if(read_rw = '0') then
					if(read_cnt = "00000") then
						read_shift_reg <= read_reg(14 downto 0);
						miso_reg <= read_reg(15);							
					else
						read_shift_reg <= read_shift_reg(13 downto 0) & '0';
						miso_reg <= read_shift_reg(14);
					end if;
				end if;
			else
				if(read_rw = '0') then
					if(read_cnt = "01000") then
						read_shift_reg <= read_reg(BITS_NUM-2 downto 0);
						miso_reg <= read_reg(BITS_NUM-1);
					else
						read_shift_reg <= read_shift_reg(BITS_NUM-3 downto 0) & '0';
						miso_reg <= read_shift_reg(BITS_NUM-2);
					end if;
				end if;
			end if;
		end if;
		
	end process;
--------------------------------------------------------------------
	MISO <= miso_reg;
	MISO_OE <= not read_rw;
--------------------------------------------------------------------

--__________________________________________________________________
--==================================================================
-- Register Write Operation
--==================================================================
--------------------------------------------------------------------
	process (RST_OR, SCLK) begin		
		if(RST_OR = '1') then
			write_reg <= (others => '0');
		elsif(SCLK'event and SCLK = '1') then
			write_reg <= write_reg(7+BITS_NUM-1 downto 0) & MOSI;
		end if;
	end process;
--------------------------------------------------------------------
-- RW | A6 A5 A4 A3 A2 A1 A0 | D15 D14 ....D0
-- RW | A6 A5 A4 A3 A2 A1 A0 | D7  D8  ....D0
	write_rw <= write_reg(7+BITS_NUM);						-- MSB
	write_addr <= write_reg(7+BITS_NUM-1 downto BITS_NUM);	-- A6~A0
	write_data <= write_reg(BITS_NUM-1 downto 0);			-- D15~D0 or D7~D0
		
--------------------------------------------------------------------
--	process (RST, CSN, write_data) begin		
	process (RST, SCLK_INV, INIT_WREG)
	begin				-- Please Change Default Values for TX 	
		if(RST = '1') then		
			FOR i IN 0 TO (RWMEM_D-1) LOOP
				rwmem_array(i) <= INIT_WREG((i+1)*BITS_NUM-1 downto i*BITS_NUM);	
			END LOOP;
		elsif(SCLK_INV'event and SCLK_INV = '1') then
			if(RW_FLAG = '0') then		
					rwmem_array(0) <= write_reg(15 downto 0);	
			else
				------------------------------------------------------------	
				if(write_rw = '1') and (conv_integer1(write_addr) < RWMEM_D) then 
					rwmem_array(conv_integer1(write_addr)) <= write_data(BITS_NUM-1 downto 0);	
				end if;				
				------------------------------------------------------------						
			end if;
		end if;
	end process;
--------------------------------------------------------------------
--	process (rwmem_array) begin	
--		FOR i IN 0 TO (RWMEM_D-1) LOOP
--			WREG((i+1)*16-1 downto i*16) <= rwmem_array(i);	
--		END LOOP;
--	end process;

	process (RST, CSN, INIT_WREG) begin		
		if(RST = '1') then		
			FOR i IN 0 TO (RWMEM_D-1) LOOP
				WREG((i+1)*BITS_NUM-1 downto i*BITS_NUM) <= INIT_WREG((i+1)*BITS_NUM-1 downto i*BITS_NUM);
			END LOOP;
		elsif(CSN'event and CSN = '1') then
			FOR i IN 0 TO (RWMEM_D-1) LOOP
				WREG((i+1)*BITS_NUM-1 downto i*BITS_NUM) <= rwmem_array(i);	
			END LOOP;
		end if;
	end process;

	process (RREG) begin	
		FOR j IN 0 TO (ROMEM_D-1) LOOP
			romem_array(j) <= RREG((j+1)*BITS_NUM-1 downto j*BITS_NUM);
		END LOOP;
	end process;
--------------------------------------------------------------------

--------------------------------------------------------------------  
end Behavioral;
--------------------------------------------------------------------  
--==================================================================
