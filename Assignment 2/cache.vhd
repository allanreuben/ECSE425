library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
generic(
	ram_size : INTEGER := 32768;
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
	-- Size of cache in bytes and blocks
	constant CACHE_SIZE_BYTES: natural := 512;
	constant BYTES_PER_BLOCK: natural := 16;
	constant CACHE_SIZE_BLOCKS: natural := CACHE_SIZE_BYTES / BYTES_PER_BLOCK;
	-- Size of tag and offset in bits
	constant TAG_SIZE: natural := 11;
	constant OFFSET_SIZE: natural := 2;
	-- An array type for the data in the cache
	type cache_data is array(CACHE_SIZE_BYTES-1 downto 0) of std_logic_vector(7 downto 0);
	-- An array type for the tags in the cache
	type cache_tags is array(CACHE_SIZE_BLOCKS-1 downto 0) of std_logic_vector(TAG_SIZE-1 downto 0);
	-- An array type for the valid(1)/invalid(0) and dirty(1)/clean(0) flags
	type cache_flags is array(CACHE_SIZE_BLOCKS-1 downto 0) of std_logic_vector(1 downto 0);

	-- Cache structures
	signal cache_d: cache_data;
	signal cache_t: cache_tags;
	signal cache_f: cache_flags;
	-- Wait request signal
	signal waitreq_reg: std_logic := '1';
	signal tag_reg: std_logic_vector(TAG_SIZE-1 downto 0);
	-- Variables
	variable block_idx: natural;
begin

	cache_proc: process (clock, reset)
	begin
		-- Initialize the arrays
		if (reset = '1') or (now < 1 ps) then
			for i in 0 to CACHE_SIZE_BYTES-1 loop
				cache_d(i) <= "00000000";
			end loop;
			-- Initialize the tags and flags
			for i in 0 to CACHE_SIZE_BLOCKS-1 loop
				cache_t(i) <= std_logic_vector(to_unsigned(0, TAG_SIZE));
				-- Initialize the tag to invalid and clean
				cache_f(i) <= "00";
			end loop;

		-- Main processing block
		elsif (rising_edge(clock)) then
			if (s_read) then
				tag_reg <= s_addr(14 downto 14-TAG_SIZE+1);
				block_idx := to_integer(unsigned(tag_reg)) mod CACHE_SIZE_BLOCKS;
				-- Check if tag matches
				if (tag_reg = cache_t(block_idx)) then
					-- Check if block is valid
					if (cache_f(block_idx)(1) = '1') then
						-- Return data found at that address in cache
					else
						-- Request the data from the main memory
					end if;
				else
					-- Check if block is dirty
					if (cache_f(block_idx)(0) = '1') then
						-- Write back the current block to main memory
						-- Request the data from the main memory
						-- Mark the cache block as clean
					else
						-- Request the data from the main memory
					end if;
				end if;
			elsif (s_write) then
				tag_reg <= s_addr(14 downto 14-TAG_SIZE+1);
				block_idx := to_integer(unsigned(tag_reg)) mod CACHE_SIZE_BLOCKS;
				-- Check if tag matches
				if (tag_reg = cache_t(block_idx)) then
					-- Check if block is valid
					if (cache_f(block_idx)(1) = '1') then
						-- Write the data into the cache block
						-- Mark the block as dirty
					else
						-- Get the new block from the main memory
						-- Write the data into the cache block
						-- Mark the block as dirty
					end if;
				else
					-- Check if block is dirty
					if (cache_f(block_idx)(0) = '1') then
						-- Write the old cache block to the main memory
						-- Get the new block from the main memory
						-- Write the new data into the cache block
					else
						-- Get the new block from the main memory
						-- Write the new data into the cache blocck
						-- Mark the block as dirty
					end if;
				end if;
			else
				-- Just vibe
			end if;
		end if;

		s_waitrequest <= waitreq_reg;
	end process;

end arch;