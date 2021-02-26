library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
generic(
	ram_size : INTEGER := 32768
);
port(
	clock : in std_logic;
	reset : in std_logic;
	
	-- Avalon interface --
	s_addr : in std_logic_vector (31 downto 0);
	s_read : in std_logic;
	s_readdata : out std_logic_vector (31 downto 0);
	s_write : in std_logic;
	s_writedata : in std_logic_vector (31 downto 0);
	s_waitrequest : out std_logic; 
    
	m_addr : out integer range 0 to ram_size-1;
	m_read : out std_logic;
	m_readdata : in std_logic_vector (7 downto 0);
	m_write : out std_logic;
	m_writedata : out std_logic_vector (7 downto 0);
	m_waitrequest : in std_logic
);
end cache;

architecture arch of cache is
	--------------- CONSTANTS ---------------
	-- Size of cache in bytes and blocks
	constant CACHE_SIZE_WORDS: natural := 128;
	constant WORDS_PER_BLOCK: natural := 4;
	constant CACHE_SIZE_BLOCKS: natural := CACHE_SIZE_WORDS / WORDS_PER_BLOCK;
	-- Location where useful address data begins
	constant ADDRESS_START: natural := 14;
	-- Locations of the last bit of the tag, block address, and block offset
	constant TAG_END_BIT: natural := 9;
	constant BLOCK_ADDR_END_BIT: natural := 4;
	constant OFFSET_END_BIT: natural := 2;
	-- Some sizes
	constant TAG_SIZE: natural := ADDRESS_START - TAG_END_BIT + 1;
	-- Mask for the block address
	constant BLOCK_ADDR_MASK: unsigned(ADDRESS_START downto 0) := (
		ADDRESS_START downto OFFSET_END_BIT + 2 => '1',
		others => '0'
	);

	--------------- TYPE DEFINITIONS ---------------
	-- An array type for the data in the cache
	type cache_data is array(CACHE_SIZE_WORDS-1 downto 0) of std_logic_vector(31 downto 0);
	-- An array type for the tags in the cache
	type cache_tags is array(CACHE_SIZE_BLOCKS-1 downto 0) of std_logic_vector(TAG_SIZE-1 downto 0);
	-- An array type for the valid(1)/invalid(0) and dirty(1)/clean(0) flags
	type cache_flags is array(CACHE_SIZE_BLOCKS-1 downto 0) of std_logic_vector(1 downto 0);

	--------------- SIGNALS ---------------
	-- Cache structures
	signal cache_d: cache_data;
	signal cache_t: cache_tags;
	signal cache_f: cache_flags;
	-- Registers for outputs to the CPU
	signal cpu_waitreq: std_logic := '1'; -- Wait request signal being monitored by the CPU
	signal cpu_readdata: std_logic_vector(31 downto 0); -- The data to be read by the CPU
	-- Registers for inputs to the main memory
	signal mem_addr: integer range 0 to ram_size-1; -- Address of target byte in memory
	signal mem_read: std_logic := '0'; -- High when reading from main memory
	signal mem_write: std_logic := '0'; -- High when writing to main memory
	signal mem_writedata: std_logic_vector(7 downto 0); -- The byte to write to the main memory
	-- Internal signals
	signal c_readdata: std_logic_vector(31 downto 0); -- Data read from the main memory
	signal c_byteoffset: integer range 0 to 3 := 0; -- Byte offset relative to current block being processed
	signal c_wordoffset: integer range 0 to 3 := 0; -- Word offset relative to current block being processed
	signal c_readnextbyte: std_logic := '0'; -- Set high if another byte should be read from the memory
	signal c_writenextbyte: std_logic := '0'; -- Set high if another byte should be written to the memory
	signal c_rthenwc: std_logic := '0'; -- Set high if the cache should read from main memory then write to cache
	-- Signals for storing parts of the address specified by the CPU
	signal tag: std_logic_vector(TAG_SIZE-1 downto 0); -- Tag of the address specified by the CPU
	signal block_idx: natural range 0 to CACHE_SIZE_BLOCKS-1; -- Block index of the address specified by the CPU
	signal offset: natural range 0 to WORDS_PER_BLOCK-1; -- Offset of the address specified by the CPU
begin

	cache_proc: process (clock, reset)
	begin
		-- Initialize the arrays
		if (reset = '1') or (now < 1 ps) then
			for i in 0 to CACHE_SIZE_WORDS-1 loop
				cache_d(i) <= "00000000000000000000000000000000";
			end loop;
			-- Initialize the tags and flags
			for i in 0 to CACHE_SIZE_BLOCKS-1 loop
				cache_t(i) <= std_logic_vector(to_unsigned(0, TAG_SIZE));
				-- Initialize the tag to invalid and clean
				cache_f(i) <= "00";
			end loop;

		-- Main processing block
		elsif (rising_edge(clock)) then
			-- Used to trigger the main memory for a new read
			if (c_readnextbyte = '1') then
				c_readnextbyte <= '0';
				mem_read <= '1';
			-- Used to trigger the main memory for a new write
			elsif (c_writenextbyte = '1') then
				c_writenextbyte <= '0';
				mem_write <= '1';
			-- Present the read data to the CPU for one clock cycle
			elsif (cpu_waitreq = '0') then
				cpu_waitreq <= '1';
			-- Writing to memory always happens before reading, so check for write first
			elsif (mem_write = '1') then
				-- Check if byte has been written to the main memory
				if (m_waitrequest = '0') then
					-- Byte was succesfully written to the main memory
					c_byteoffset <= c_byteoffset + 1;
					if (c_byteoffset = 4) then
						-- Word has been written to the main memory
						c_byteoffset <= 0;
						c_wordoffset <= c_wordoffset + 1;
						if (c_wordoffset = 4) then
							-- Block has been written to the main memory
							c_writenextbyte <= '0';
							-- The cache will always read after writing to the main memory
							mem_addr <= to_integer(unsigned(s_addr(ADDRESS_START downto 0)) and BLOCK_ADDR_MASK);
							c_byteoffset <= 0;
							c_wordoffset <= 0;
							mem_read <= '1';
						else
							c_writenextbyte <= '1';
						end if;
					else
						c_writenextbyte <= '1';
					end if;
					mem_writedata <= cache_d(block_idx*WORDS_PER_BLOCK + c_wordoffset)
						(31 - c_byteoffset*8 downto 24 - c_byteoffset*8);
					mem_write <= '0';
				end if;
			elsif (mem_read = '1') then
				if (m_waitrequest = '0') then
					-- Interpret memory data as big endian
					c_readdata(31 - c_byteoffset*8 downto 24 - c_byteoffset*8) <= m_readdata;
					c_byteoffset <= c_byteoffset + 1;
					if (c_byteoffset < 4) then
						-- Still need to read more bytes from memory
						mem_addr <= mem_addr + 1;
						c_readnextbyte <= '1';
					else
						-- We have loaded an entire word, so we can store it in cache
						cache_d(block_idx*WORDS_PER_BLOCK + c_wordoffset) <= c_readdata;
						c_wordoffset <= c_wordoffset + 1;
						if (c_wordoffset < 4) then
							-- Still need to read more words
							mem_addr <= mem_addr + 1;
							c_byteoffset <= 0;
							c_readnextbyte <= '1';
						else
							-- We loaded the entire block, so we can return value requested by the CPU
							c_wordoffset <= 0;
							cpu_readdata <= cache_d(block_idx*WORDS_PER_BLOCK + offset);
							if (c_rthenwc = '1') then
								-- Write the new value into the cache
								cache_d(block_idx*WORDS_PER_BLOCK + offset) <= s_writedata;
								-- Mark the block as valid and dirty
								cache_f(block_idx) <= "11";
								-- Lower the rthenwc flag
								c_rthenwc <= '0';
							else
								-- Block is now valid and clean
								cache_f(block_idx) <= "10";
							end if;
							cpu_waitreq <= '0';
						end if;
					end if;
					mem_read <= '0';
				end if;
			elsif (s_read = '1') then
				tag <= s_addr(ADDRESS_START downto TAG_END_BIT);
				block_idx <= to_integer(unsigned(s_addr(TAG_END_BIT-1 downto BLOCK_ADDR_END_BIT)));
				offset <= to_integer(unsigned(s_addr(BLOCK_ADDR_END_BIT-1 downto OFFSET_END_BIT)));
				-- Check if tag matches
				if (tag = cache_t(block_idx)) then
					-- Check if block is valid
					if (cache_f(block_idx)(1) = '1') then
						-- Return data found at that address in cache
						cpu_readdata <= cache_d(block_idx*WORDS_PER_BLOCK + offset);
						cpu_waitreq <= '0';
					else
						-- Request the data from the main memory
						mem_addr <= to_integer(unsigned(s_addr(ADDRESS_START downto 0)) and BLOCK_ADDR_MASK);
						c_byteoffset <= 0;
						c_wordoffset <= 0;
						mem_read <= '1';
					end if;
				else
					-- Check if block is dirty
					if (cache_f(block_idx)(0) = '1') then
						-- Write back the current block to main memory
						-- Shift the tag of the current block and add it to the block index to get the address in memory
						mem_addr <= to_integer(shift_left(resize(unsigned(cache_t(block_idx)), ADDRESS_START + 1), TAG_END_BIT))
							+ block_idx;
						mem_writedata <= cache_d(block_idx*WORDS_PER_BLOCK)(31 downto 24);
						c_byteoffset <= 0;
						c_wordoffset <= 0;
						mem_write <= '1';
						-- Request the new block from the main memory
							-- Writing to memory always results in a read
						-- Mark the new cache block as clean
							-- Taken care of in the read method
					else
						-- Request the data from the main memory
						mem_addr <= to_integer(unsigned(s_addr(ADDRESS_START downto 0)) and BLOCK_ADDR_MASK);
						c_byteoffset <= 0;
						c_wordoffset <= 0;
						mem_read <= '1';
					end if;
				end if;
			elsif (s_write = '1') then
				tag <= s_addr(ADDRESS_START downto TAG_END_BIT);
				block_idx <= to_integer(unsigned(s_addr(TAG_END_BIT-1 downto BLOCK_ADDR_END_BIT)));
				offset <= to_integer(unsigned(s_addr(BLOCK_ADDR_END_BIT-1 downto OFFSET_END_BIT)));
				-- Check if tag matches
				if (tag = cache_t(block_idx)) then
					-- Check if block is valid
					if (cache_f(block_idx)(1) = '1') then
						-- Write the data into the cache block
						cache_d(block_idx*WORDS_PER_BLOCK + offset) <= s_writedata;
						-- Mark the block as dirty and valid
						cache_f(block_idx) <= "11";
						-- Lower the waitrequest signal
						cpu_waitreq <= '0';
					else
						-- Get the new block from the main memory
						mem_addr <= to_integer(unsigned(s_addr(ADDRESS_START downto 0)) and BLOCK_ADDR_MASK);
						c_byteoffset <= 0;
						c_wordoffset <= 0;
						mem_read <= '1';
						-- Write the data into the cache block
						c_rthenwc <= '1'; -- Ensures that the new value is written to the cache
					end if;
				else
					-- Check if block is dirty
					if (cache_f(block_idx)(0) = '1') then
						-- Write the old cache block to the main memory
						mem_addr <= to_integer(shift_left(resize(unsigned(cache_t(block_idx)), ADDRESS_START + 1), TAG_END_BIT))
							+ block_idx;
						mem_writedata <= cache_d(block_idx*WORDS_PER_BLOCK)(31 downto 24);
						c_byteoffset <= 0;
						c_wordoffset <= 0;
						mem_write <= '1';
						-- Get the new block from the main memory
							-- Read always happens after write to memory
						-- Write the new data into the cache block
						c_rthenwc <= '1';
					else
						-- Get the new block from the main memory
						mem_addr <= to_integer(unsigned(s_addr(ADDRESS_START downto 0)) and BLOCK_ADDR_MASK);
						c_byteoffset <= 0;
						c_wordoffset <= 0;
						mem_read <= '1';
						-- Write the data into the cache block
						c_rthenwc <= '1'; -- Ensures that the new value is written to the cache
					end if;
				end if;
			end if;
		end if;
	end process;

	s_waitrequest <= cpu_waitreq;
	s_readdata <= cpu_readdata;

	m_addr <= mem_addr;
	m_read <= mem_read;
	m_write <= mem_write;
	m_writedata <= mem_writedata;
end arch;
