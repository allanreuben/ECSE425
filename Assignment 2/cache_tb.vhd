library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is

component cache is
generic(
    ram_size : INTEGER := 32768);
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
end component;

component memory is 
GENERIC(
    ram_size : INTEGER := 32768;
    mem_delay : time := 10 ns;
    clock_period : time := 1 ns
);
PORT (
    clock: IN STD_LOGIC;
    writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    address: IN INTEGER RANGE 0 TO ram_size-1;
    memwrite: IN STD_LOGIC;
    memread: IN STD_LOGIC;
    readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    waitrequest: OUT STD_LOGIC
);
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal s_addr : std_logic_vector (31 downto 0);
signal s_read : std_logic;
signal s_readdata : std_logic_vector (31 downto 0);
signal s_write : std_logic;
signal s_writedata : std_logic_vector (31 downto 0);
signal s_waitrequest : std_logic;

signal m_addr : integer range 0 to 2147483647;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (7 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (7 downto 0);
signal m_waitrequest : std_logic; 

-- Function to easily create an address (makes code more readable)
function to_address(tag, block_index, word_offset : integer) return std_logic_vector is
    variable addr : std_logic_vector(31 downto 0);
begin
    addr(31 downto 15) := (others => '0');
    addr(14 downto 9)  := std_logic_vector(to_unsigned(tag, 6));
    addr(8 downto 4)   := std_logic_vector(to_unsigned(block_index, 5));
    addr(3 downto 2)   := std_logic_vector(to_unsigned(word_offset, 2));
    addr(1 downto 0)   := (others => '0'); -- Byte offset 0
    return addr;
end to_address;

-- Assert will be used many times so package and track the amount of errors
procedure assert_equal(actual, expected : in std_logic_vector(31 downto 0); error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
            report "Error count: " & integer'image(error_count);
        end if;
        assert (actual = expected) report "Expected " & integer'image(to_integer(signed(expected))) & " but the data was " & integer'image(to_integer(signed(actual))) severity error;
    end assert_equal;

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    clock => clk,
    reset => reset,

    s_addr => s_addr,
    s_read => s_read,
    s_readdata => s_readdata,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,

    m_addr => m_addr,
    m_read => m_read,
    m_readdata => m_readdata,
    m_write => m_write,
    m_writedata => m_writedata,
    m_waitrequest => m_waitrequest
);

MEM : memory
port map (
    clock => clk,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
    memread => m_read,
    readdata => m_readdata,
    waitrequest => m_waitrequest
);
				

clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
    variable error_count : integer := 0;
begin

    Report "Starting test bench";
    -- Reset cache
    reset <= '1';
    s_write <= '0';
    s_read <='0';
	WAIT FOR clk_period;
	reset <= '0';
    WAIT FOR clk_period;

    -- Test case 1: Write tag equal invalid clean
    -- Tag equal because we initalize to 000000
    report "Test 1: Write tag equal invalid clean";
    s_write      <= '1';
    s_addr       <= to_address(0,1,0);
    s_writedata  <= x"BABBBCBD";
    wait until falling_edge(s_waitrequest);
    s_write      <= '0';
    wait until rising_edge(clk);
    

    -- Test case 2: Read tag equal invalid clean
    -- Tag equal because we initalize to 000000
    -- Reads data already present in memory
    report "Test 2: Read tag equal invalid clean";
    s_read      <= '1';
    s_addr      <= to_address(0,0,0);
    wait until falling_edge(s_waitrequest);
    assert_equal(s_readdata, x"00010203", error_count);
    s_read      <= '0';
    wait until rising_edge(clk);


    -- Test case 3: Read tag equal valid dirty
    -- Reads data written in case 1, success confirms case 1 and 3 both work
    report "Test 3: Read tag equal valid dirty";
    s_read      <= '1';
    s_addr      <= to_address(0,1,0);
    wait until falling_edge(s_waitrequest);
    assert_equal(s_readdata, x"BABBBCBD", error_count);
    s_read      <= '0';
    wait until rising_edge(clk);


    -- Test case 4: Write tag not equal invalid clean
    report "Test 4: Write tag not equal invalid clean";
    s_write      <= '1';
    s_addr       <= to_address(1,2,0);
    s_writedata  <= x"EAEBECED";
    wait until falling_edge(s_waitrequest);
    s_write      <= '0';
    wait until rising_edge(clk);


    -- Test case 5: Write tag equal valid dirty
    report "Test 5: Write tag equal valid dirty";
    s_write      <= '1';
    s_addr       <= to_address(0,1,0);
    s_writedata  <= x"ABACADAE";
    -- We wait until 1 cc after waitrequest falls to 0
    wait until falling_edge(s_waitrequest);
    s_write      <= '0';
    wait until rising_edge(clk);


    -- Test case 6: Write tag not equal valid dirty
    report "Test 6: Write tag not equal valid dirty";
    s_write      <= '1';
    s_addr       <= to_address(2,1,0);
    s_writedata  <= x"DADBDCDD";
    wait until falling_edge(s_waitrequest);
    s_write      <= '0';
    wait until rising_edge(clk);


    -- Test case 7: Read tag not equal valid dirty
    report "Test 7: Read tag not equal valid dirty";
    s_read      <= '1';
    s_addr      <= to_address(0,1,0);
    wait until falling_edge(s_waitrequest);
    assert_equal(s_readdata, x"ABACADAE", error_count);
    s_read      <= '0';
    wait until rising_edge(clk);


    -- Test case 8: Read tag equal valid clean
    report "Test 8: Read tag equal valid clean";
    s_read      <= '1';
    s_addr      <= to_address(0,1,0);
    wait until falling_edge(s_waitrequest);
    assert_equal(s_readdata, x"ABACADAE", error_count);
    s_read      <= '0';
    wait until rising_edge(clk);


    -- Test case 9: Read tag not equal valid clean
    report "Test 9: Read tag not equal valid clean";
    s_read      <= '1';
    s_addr      <= to_address(2,1,0);
    wait until falling_edge(s_waitrequest);
    assert_equal(s_readdata, x"DADBDCDD", error_count);
    s_read      <= '0';
    wait until rising_edge(clk);
    

    -- Test case 10: Write tag equal valid clean
    report "Test 10: Write tag equal valid clean";
    s_write     <= '1';
    s_addr      <= to_address(2,1,0);
    s_writedata <= x"12131415";
    wait until falling_edge(s_waitrequest);
    s_write     <= '0';
    wait until rising_edge(clk);


    -- Test case 11: Write tag not equal valid clean
    report "Test 11: Write tag not equal valid clean";
    -- First read to make clean
    s_read      <= '1';
    s_addr      <= to_address(0,2,0);
    wait until falling_edge(s_waitrequest);
    assert_equal(s_readdata, x"20212223", error_count);
    s_read      <= '0';
    wait until rising_edge(clk);

    -- Next write with a different tag
    s_write     <= '1';
    s_addr      <= to_address(0,2,0);
    s_writedata <= x"12131415";
    wait until falling_edge(s_waitrequest);
    s_write     <= '0';
    wait until rising_edge(clk);


    -- Test case 12: Read tag not equal invalid clean
    Report "Resetting cache";
    -- Reset cache
    reset <= '1';
    s_write <= '0';
    s_read <='0';
    WAIT FOR clk_period;
    reset <= '0';
    WAIT FOR clk_period;

    Report "Test 12: Read tag not equal invalid clean";
    -- NOTE: Data at (2,1,0) is DADBDCDD and NOT 12131415 as the cache data is not saved during reset
    s_read      <= '1';
    s_addr      <= to_address(2,1,0);
    wait until falling_edge(s_waitrequest);
    assert_equal(s_readdata, x"DADBDCDD", error_count);
    s_read      <= '0';
    report "Error count: " & integer'image(error_count);
    wait until rising_edge(clk);

    Report "Testbench complete";
    
end process;
	
end;