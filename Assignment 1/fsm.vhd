library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

-- Do not modify the port map of this structure
entity comments_fsm is
port (clk : in std_logic;
      reset : in std_logic;
      input : in std_logic_vector(7 downto 0);
      output : out std_logic
  );
end comments_fsm;

architecture behavioral of comments_fsm is

-- The ASCII value for the '/', '*' and end-of-line characters
constant SLASH_CHARACTER : std_logic_vector(7 downto 0) := "00101111";
constant STAR_CHARACTER : std_logic_vector(7 downto 0) := "00101010";
constant NEW_LINE_CHARACTER : std_logic_vector(7 downto 0) := "00001010";

signal state : std_logic_vector(2 downto 0) := "000";

begin

-- Insert your processes here
process (clk, reset)
begin
    if (reset = '0') then
        state <= "000";
    elsif (rising_edge(clk)) then
        case (state) is
            when "000" =>
                if (input = SLASH_CHARACTER) then
                    state <= "001";
                    output <= '0';
                else
                    state <= "000";
                    output <= '0';
                end if;
            when "001" =>
                if (input = STAR_CHARACTER) then
                    state <= "010";
                    output <= '0';
                elsif (input = SLASH_CHARACTER) then
                    state <= "101";
                    output <= '0';
                else
                    state <= "000";
                    output <= '0';
                end if;
            when "010" =>
                if (input = STAR_CHARACTER) then
                    state <= "011";
                    output <= '1';
                else
                    state <= "100";
                    output <= '1';
                end if;
            when "011" =>
                if (input = STAR_CHARACTER) then
                    state <= "011";
                    output <= '1';
                elsif (input = SLASH_CHARACTER) then
                    state <= "111";
                    output <= '1';
                else
                    state <= "100";
                    output <= '1';
                end if;
            when "100" =>
                if (input = STAR_CHARACTER) then
                    state <= "011";
                    output <= '1';
                else
                    state <= "100";
                    output <= '1';
                end if;
            when "101" | "110" =>
                if (input = NEW_LINE_CHARACTER) then
                    state <= "111";
                    output <= '1';
                else
                    state <= "110";
                    output <= '1';
                end if;
            when "111" =>
                if (input = SLASH_CHARACTER) then
                    state <= "001";
                    output <= '0';
                else
                    state <= "000";
                    output <= '0';
                end if;
            when others =>
                state <= state;
        end case;
    else
        state <= state;
    end if;
end process;

end behavioral;