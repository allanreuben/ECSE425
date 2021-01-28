LIBRARY ieee;
USE ieee.STD_LOGIC_1164.all;

ENTITY fsm_tb IS
END fsm_tb;

ARCHITECTURE behaviour OF fsm_tb IS

COMPONENT comments_fsm IS
PORT (clk : in std_logic;
      reset : in std_logic;
      input : in std_logic_vector(7 downto 0);
      output : out std_logic
  );
END COMPONENT;

--The input signals with their initial values
SIGNAL clk, s_reset, s_output: STD_LOGIC := '0';
SIGNAL s_input: std_logic_vector(7 downto 0) := (others => '0');

CONSTANT clk_period : time := 1 ns;
CONSTANT SLASH_CHARACTER : std_logic_vector(7 downto 0) := "00101111";
CONSTANT STAR_CHARACTER : std_logic_vector(7 downto 0) := "00101010";
CONSTANT NEW_LINE_CHARACTER : std_logic_vector(7 downto 0) := "00001010";

BEGIN
dut: comments_fsm
PORT MAP(clk, s_reset, s_input, s_output);

 --clock process
clk_process : PROCESS
BEGIN
	clk <= '0';
	WAIT FOR clk_period/2;
	clk <= '1';
	WAIT FOR clk_period/2;
END PROCESS;
 
--TODO: Thoroughly test your FSM
stim_process: PROCESS
BEGIN    
	REPORT "Case moving from state 0 to 0, expected output 0";
	s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a meaningless character, the output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 0 to 1, expected output 0";
	s_input <= "00101111"; -- slash character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After first state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 1 to 2, expected output 0";
	s_input <= "00101010"; -- star character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 2 to 3, expected output 1";
	s_input <= "00101010"; -- star character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "After state transition, output should be '1'" SEVERITY ERROR;
	
	REPORT "Case moving from state 3 to 3, expected output 1";
	s_input <= "00101010"; -- star character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "After no state transition, output should be '1'" SEVERITY ERROR;

	REPORT "Case moving from state 3 to 4, expected output 1";
	s_input <= "01111110"; -- meaningless character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "After state transition, output should be '1'" SEVERITY ERROR;

	REPORT "Case moving from state 4 to 4, expected output 1";
	s_input <= "01111110"; -- meaningless character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "After no state transition, output should be '1'" SEVERITY ERROR;

	REPORT "Case moving from state 4 to 3, expected output 1";
	s_input <= "00101010"; -- star character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "After state transition, output should be '1'" SEVERITY ERROR;

	REPORT "Case moving from state 3 to 7, expected output 1";
	s_input <= "00101111"; -- slash character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "After state transition, output should be '1'" SEVERITY ERROR;

	REPORT "Case moving from state 7 to 0, expected output 0";
	s_input <= "01111110"; -- meaningless character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 0 to 0 with new line, expected output 0";
	s_input <= "00001010"; -- new line character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After no state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 0 to 1, expected output 0";
	s_input <= "00101111"; -- slash character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After first state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 1 to 5, expected output 0";
	s_input <= "00101111"; -- slash character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 5 to 6, expected output 1";
	s_input <= "01111110"; -- meaningless character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "After state transition, output should be '1'" SEVERITY ERROR;

	REPORT "Case moving from state 6 to 6, expected output 1";
	s_input <= "01111110"; -- meaningless character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "After no state transition, output should be '1'" SEVERITY ERROR;

	REPORT "Case moving from state 6 to 7, expected output 1";
	s_input <= "00001010"; -- new line character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "After state transition, output should be '1'" SEVERITY ERROR;

	REPORT "Case moving from state 7 to 1, expected output 0";
	s_input <= "00101111"; -- slash character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 1 to 2, expected output 0";
	s_input <= "00101010"; -- star character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 2 to 4, expected output 1";
	s_input <= "01111110"; -- meaningless character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "After no state transition, output should be '1'" SEVERITY ERROR;

	REPORT "Case RESET from state 4 to 0, expected output 0";
	s_reset <= "1";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After RESET, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 0 to 1, expected output 0";
	s_input <= "00101111"; -- slash character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After first state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 1 to 5, expected output 0";
	s_input <= "00101111"; -- slash character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 5 to 7, expected output 1";
	s_input <= "00001010"; -- new line character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "After state transition, output should be '1'" SEVERITY ERROR;

	REPORT "Case moving from state 7 to 1, expected output 0";
	s_input <= "00101111"; -- slash character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Case moving from state 1 to 0, expected output 0";
	s_input <= "01111110"; -- meaningless character
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "After state transition, output should be '0'" SEVERITY ERROR;

	REPORT "Test suite complete";
	
	WAIT;
END PROCESS stim_process;
END;
