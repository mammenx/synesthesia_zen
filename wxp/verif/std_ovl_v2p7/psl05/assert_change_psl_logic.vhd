-- Accellera Standard V2.5 Open Verification Library (OVL).
-- Accellera Copyright (c) 2010. All rights reserved.

--******************************************************************
--Module to be replicated for assert checks
--This module is bound to the PSL vunits with assert checks
--******************************************************************
library ieee;
use ieee.std_logic_1164.all;
use work.std_ovl.all;
use work.std_ovl_procs.all;

entity assert_change_assert is 
  generic (
    width               : integer                 := 8; 
    num_cks             : integer                 := 2 
  );
  port(clk : std_logic; reset_n : std_logic; start_event : std_logic; test_expr : std_logic_vector(width-1 downto 0); window : std_logic; 
       ignore_new_start : std_logic; reset_on_new_start : std_logic; error_on_new_start : std_logic; xzcheck_enable : ovl_ctrl);
end entity;

architecture rtl of assert_change_assert is
begin
end architecture;

--******************************************************************
--Module to be replicated for assume checks
--This module is bound to the PSL vunits with assume checks
--******************************************************************
library ieee;
use ieee.std_logic_1164.all;
use work.std_ovl.all;
use work.std_ovl_procs.all;

entity assert_change_assume is 
  generic (
    width               : integer                 := 8; 
    num_cks             : integer                 := 2 
  );
  port(clk : std_logic; reset_n : std_logic; start_event : std_logic; test_expr : std_logic_vector(width-1 downto 0); window : std_logic; 
       ignore_new_start : std_logic; reset_on_new_start : std_logic; error_on_new_start : std_logic; xzcheck_enable : ovl_ctrl);
end entity;

architecture rtl of assert_change_assume is
begin
end architecture;

--******************************************************************
--Module to be replicated for assume checks
--This module is bound to the PSL vunits with assume checks
--******************************************************************
library ieee;
use ieee.std_logic_1164.all;
use work.std_ovl.all;
use work.std_ovl_procs.all;

entity assert_change_cover is 
  generic (
    OVL_COVER_BASIC_ON  : integer                 := 1; 
    OVL_COVER_CORNER_ON : integer                 := 1 
  );
  port(clk : std_logic; reset_n : std_logic; start_event : std_logic; window : std_logic; reset_on_new_start : std_logic; window_close : std_logic);
end entity;

architecture rtl of assert_change_cover is
begin
end architecture;


library ieee;
use ieee.std_logic_1164.all;
use work.std_ovl.all;
use work.std_ovl_procs.all;

architecture rtl of assert_change is 
  constant assert_name         : string := "ASSERT_CHANGE";
  constant path                : string := rtl'path_name;
  
  signal reset_n               : std_logic;
  signal clk                   : std_logic;
  signal ignore_new_start      : std_logic := '0';
  signal reset_on_new_start    : std_logic := '0';
  signal error_on_new_start    : std_logic := '0';
  signal window                : std_logic := '0';
  signal temp_window_close     : std_logic := '0';
  signal i                     : integer   := 0;

component assert_change_assert is 
  generic (
    width               : integer                 := 8; 
    num_cks             : integer                 := 2 
  );
  port(clk : std_logic; reset_n : std_logic; start_event : std_logic; test_expr : std_logic_vector(width-1 downto 0); window : std_logic; 
       ignore_new_start : std_logic; reset_on_new_start : std_logic; error_on_new_start : std_logic; xzcheck_enable : ovl_ctrl);
end component;
  
component assert_change_assume is 
  generic (
    width               : integer                 := 8; 
    num_cks             : integer                 := 2 
  );
  port(clk : std_logic; reset_n : std_logic; start_event : std_logic; test_expr : std_logic_vector(width-1 downto 0); window : std_logic; 
       ignore_new_start : std_logic; reset_on_new_start : std_logic; error_on_new_start : std_logic; xzcheck_enable : ovl_ctrl);
end component;

component assert_change_cover is 
  generic (
    OVL_COVER_BASIC_ON  : integer                 := 1; 
    OVL_COVER_CORNER_ON : integer                 := 1 
  );
  port(clk : std_logic; reset_n : std_logic; start_event : std_logic; window : std_logic; reset_on_new_start : std_logic; window_close : std_logic);
end component;

begin
 
process(reset_n,clk)
begin
if(clk='1' and clk'event) then
  if(reset_n='1') then
   C1: case action_on_new_start is
      when OVL_IGNORE_NEW_START   => ignore_new_start   <= '1';
      when OVL_RESET_ON_NEW_START => reset_on_new_start <= '1';
      when OVL_ERROR_ON_NEW_START => error_on_new_start <= '1';
      when others                 => report("Info:*** Illegal value set for parameter action_on_new_start");
  end case C1;
 end if;
end if;
end process;

ovl_p : process (clk)     
begin
  if (rising_edge(clk)) then
    if (reset_n /= '0') then
      if ((window = '0') and (start_event = '1')) then
        window <= '1';
        i <= num_cks;
      elsif (window = '1') then
        if ((i = 1) and ((reset_on_new_start = '0') or ((start_event = '0')))) then
          window <= '0';
        end if;
        if ((reset_on_new_start = '1') and (start_event = '1')) then
          i <= num_cks;
        elsif (i /= 1) then
          i <= i - 1;
        end if;
      end if;
      if (i = 1) then
        temp_window_close <= '1';
      end if;
    else 
      window <= '0';
      i <= 0;
    end if;
  end if;
end process ovl_p;
 
  ------------------------------------------------------------------------------
  -- Gating logic                                                             --
  ------------------------------------------------------------------------------
  reset_gating : entity work.std_ovl_reset_gating
    generic map 
      (reset_polarity => reset_polarity, gating_type => gating_type, controls => controls)
    port map 
      (reset => reset, enable => enable, reset_n => reset_n);
  
  clock_gating : entity work.std_ovl_clock_gating
    generic map 
      (clock_edge => clock_edge, gating_type => gating_type, controls => controls)
    port map 
      (clock => clock, enable => enable, clk => clk);

  ------------------------------------------------------------------------------
  -- Initialization message                                                   --
  ------------------------------------------------------------------------------ 
  ovl_init_msg_gen : if (controls.init_msg_ctrl = OVL_ON) generate
    ovl_init_msg_proc(severity_level, property_type, assert_name, msg, path, controls);
  end generate ovl_init_msg_gen;

  ------------------------------------------------------------------------------
  -- Assert Property
  ------------------------------------------------------------------------------ 
  ovl_assert_on_gen : if (((property_type = OVL_ASSERT) or (property_type = OVL_ASSERT_2STATE)) and ovl_2state_is_on(controls, property_type)) generate

  assert_checks : assert_change_assert
     --num_cks has been passed with the value of num_cks-1 due to repetition operator limitation in some simulator
     generic map 
       ( width => width, num_cks => check_condition_integer(num_cks>1, num_cks-1, 1)) 
      port map 
        (clk => clk, reset_n => reset_n, start_event => start_event, test_expr => test_expr, window => window, 
         ignore_new_start => ignore_new_start, reset_on_new_start => reset_on_new_start, error_on_new_start => error_on_new_start, xzcheck_enable => controls.xcheck_ctrl);
  end generate ovl_assert_on_gen;
 
  ------------------------------------------------------------------------------
  -- Assume Property
  ------------------------------------------------------------------------------ 
  ovl_assume_on_gen : if (((property_type = OVL_ASSUME) or (property_type = OVL_ASSUME_2STATE)) and ovl_2state_is_on(controls, property_type)) generate
    assume_checks : assert_change_assume
     --num_cks has been passed with the value of num_cks-1 due to repetition operator limitation in some simulator
     generic map 
       ( width => width, num_cks => check_condition_integer(num_cks>1, num_cks-1, 1)) 
      port map 
        (clk => clk, reset_n => reset_n, start_event => start_event, test_expr => test_expr, window => window, 
         ignore_new_start => ignore_new_start, reset_on_new_start => reset_on_new_start, error_on_new_start => error_on_new_start, xzcheck_enable => controls.xcheck_ctrl);
  end generate ovl_assume_on_gen;

  ------------------------------------------------------------------------------
  -- Cover Property
  ------------------------------------------------------------------------------ 
  ovl_cover_on_gen : if ((coverage_level /= OVL_COVER_NONE) and (controls.cover_ctrl = OVL_ON)) generate
    cover_checks : assert_change_cover
      generic map (
       OVL_COVER_BASIC_ON  => coverage_level, 
       OVL_COVER_CORNER_ON => coverage_level)
      port map 
        (clk => clk, reset_n => reset_n,start_event=>start_event,  window => window, 
         reset_on_new_start => reset_on_new_start, window_close => temp_window_close);
  end generate ovl_cover_on_gen;

end architecture rtl;



