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
	constant CACHE_SIZE_BYTES: integer := 512;
	constant BYTES_PER_BLOCK: integer := 16;
	constant CACHE_SIZE_BLOCKS: integer := CACHE_SIZE_BYTES / BYTES_PER_BLOCK;
	-- Size of tag and offset in bits
	constant TAG_SIZE: integer := 11;
	constant OFFSET_SIZE: integer := 2;
	-- Bit masks for the dirty/clean and valid/invalid flags
	constant DIRTY_FLAG_MASK: std_logic_vector := "01";
	constant VALID_FLAG_MASK: std_logic_vector := "10";
	-- An array type for the data in the cache
	type cache_data is array(CACHE_SIZE_BYTES-1 downto 0) of std_logic_vector(7 downto 0);
	-- An array type for the tags in the cache
	type cache_tags is array(CACHE_SIZE_BLOCKS-1 downto 0) of std_logic_vector(TAG_SIZE-1 downto 0);
	-- An array type for the valid(1)/invalid(0) and dirty(1)/clean(0) flags
	type cache_flags is array(CACHE_SIZE_BLOCKS-1 downto 0) of std_logic_vector(1 downto 0);

	-- Signals used in the process blocks
	signal cache_d: cache_data;
	signal cache_t: cache_tags;
	signal cache_f: cache_flags;
begin

	cache_process: process (clock)
	begin
		-- Initialize the arrays
		if (now < 1 ps) then
			for i in 0 to CACHE_SIZE_BYTES-1 loop
				cache_d(i) <= "00000000";
			end loop;
			-- Initialize the tags and flags
			for i in 0 to CACHE_SIZE_BLOCKS-1 loop
				cache_t(i) <= std_logic_vector(to_unsigned(0, TAG_SIZE));
				-- Initialize the tag to invalid and clean
				cache_f(i) <= "00";
			end loop;
		end if;
	end process;

end arch;