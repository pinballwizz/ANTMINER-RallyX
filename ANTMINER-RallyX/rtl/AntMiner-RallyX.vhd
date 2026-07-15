---------------------------------------------------------------------------------
--                         Rally X - Antminer S9
--                            Code from Mist
--
--                         Modified for Antminer S9 
--                              by pinballwiz 
--                               25/06/2026
---------------------------------------------------------------------------------
-- Keyboard inputs :
--   5 : Add coin
--   2 : Start 2 players
--   1 : Start 1 player
--   Ctrl	 : Smoke
--   Up Arrow    : Move Up
--   Down Arrow  : Move Down
--   RIGHT arrow : Move Right
--   LEFT arrow  : Move Left
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------
entity rallyx_antminer is
port(
	clock_50    : in std_logic;
   	I_RESET     : in std_logic;
	O_VIDEO_R	: out std_logic_vector(2 downto 0); 
	O_VIDEO_G	: out std_logic_vector(2 downto 0);
	O_VIDEO_B	: out std_logic_vector(1 downto 0);
	O_HSYNC		: out std_logic;
	O_VSYNC		: out std_logic;
	O_AUDIO_L 	: out std_logic;
	O_AUDIO_R 	: out std_logic;
   	ps2_clk     : in std_logic;
	ps2_dat     : inout std_logic;
	led         : out std_logic_vector(7 downto 0);
	aled        : out std_logic_vector(3 downto 0);
	joy         : in std_logic_vector(7 downto 0);
	dipsw       : in std_logic_vector(7 downto 0)
 );
end rallyx_antminer;
------------------------------------------------------------------------------
architecture struct of rallyx_antminer is

 signal clock_36        : std_logic;
 signal clock_24        : std_logic;
 signal clock_18        : std_logic;
 signal clock_9         : std_logic;
 --
 signal video_r         : std_logic_vector(5 downto 0);
 signal video_g         : std_logic_vector(5 downto 0);
 signal video_b         : std_logic_vector(5 downto 0);
 --
 signal video_r_i       : std_logic_vector(5 downto 0);
 signal video_g_i       : std_logic_vector(5 downto 0);
 signal video_b_i       : std_logic_vector(5 downto 0);
 --
 signal iRGB            : std_logic_vector(11 downto 0);
 signal oRGB            : std_logic_vector(11 downto 0);
 --
 signal h_sync          : std_logic;
 signal v_sync	        : std_logic;
 signal h_blank          : std_logic;
 signal v_blank	        : std_logic;
 signal pclk	        : std_logic;
 --
 signal hpos            : std_logic_vector(8 downto 0);
 signal vpos            : std_logic_vector(8 downto 0);
 signal pout            : std_logic_vector(7 downto 0);
 --
 signal reset           : std_logic;
 --
 signal audio           : std_logic_vector(15 downto 0);
 signal dac_in          : std_logic_vector(15 downto 0);
 signal oSND            : std_logic_vector(7 downto 0);
 signal audio_pwm       : std_logic;
--
 signal SW_LEFT         : std_logic;
 signal SW_RIGHT        : std_logic;
 signal SW_UP           : std_logic;
 signal SW_DOWN         : std_logic;
 signal SW_FIRE         : std_logic;
 signal SW_BOMB         : std_logic;
 signal SW_COIN         : std_logic;
 signal P1_START        : std_logic;
 signal P2_START        : std_logic;
 -- 
 signal INP1            : std_logic_vector(7 downto 0);
 signal INP2            : std_logic_vector(7 downto 0);
 --
 signal kbd_intr        : std_logic;
 signal kbd_scancode    : std_logic_vector(7 downto 0);
 signal joy_BBBBFRLDU   : std_logic_vector(9 downto 0);
 --
 constant CLOCK_FREQ    : integer := 27E6;
 signal counter_clk     : std_logic_vector(25 downto 0);
 signal clock_4hz       : std_logic;
 signal AD              : std_logic_vector(15 downto 0);
---------------------------------------------------------------------------
component rallyx_clocks
port(
  clk_out1          : out    std_logic;
  clk_out2          : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;
---------------------------------------------------------------------------
begin

 reset <= not I_RESET;
 aled(3 downto 0) <= "1111"; -- turn unused onboard leds off
---------------------------------------------------------------------------
-- Clocks

Clocks: rallyx_clocks
    port map (
        clk_in1   => clock_50,
        clk_out1  => clock_36,
        clk_out2  => clock_24  
    );
---------------------------------------------------------------------------
-- Clocks Divide

process(clock_36)
begin
	if rising_edge(clock_36) then
		clock_18 <= not clock_18;
	end if;
end process;    
--
process(clock_18)
begin
	if rising_edge(clock_18) then
		clock_9 <= not clock_9;
	end if;
end process;    
---------------------------------------------------------------------------
-- Inputs

SW_LEFT    <= joy_BBBBFRLDU(2);-- when dipsw(0) = '0' else not joy(0);
SW_RIGHT   <= joy_BBBBFRLDU(3);-- when dipsw(0) = '0' else not joy(1);
SW_UP      <= joy_BBBBFRLDU(0);-- when dipsw(0) = '0' else not joy(2);
SW_DOWN    <= joy_BBBBFRLDU(1);-- when dipsw(0) = '0' else not joy(3);
SW_FIRE    <= joy_BBBBFRLDU(4);-- when dipsw(0) = '0' else not joy(4);
SW_BOMB    <= joy_BBBBFRLDU(8);-- when dipsw(0) = '0' else not joy(5);
SW_COIN    <= joy_BBBBFRLDU(7);-- when dipsw(0) = '0' else not joy(6);
P1_START   <= joy_BBBBFRLDU(5);-- when dipsw(0) = '0' else not joy(7);
P2_START   <= joy_BBBBFRLDU(6);-- when dipsw(0) = '0' else not joy(8);

INP1 <= not SW_COIN & not P1_START & not SW_UP & not SW_DOWN & not SW_RIGHT & not SW_LEFT & not SW_FIRE & '0';
INP2 <= '0'& not P2_START & not SW_UP & not SW_DOWN & not SW_RIGHT & not SW_LEFT & not SW_FIRE & '1';
---------------------------------------------------------------------------
-- Main

rallyx : entity work.fpga_NRX
  port map (
 CLK24M => clock_24,
 reset  => reset,
 HP     => hpos,
 VP     => vpos,
 PCLK   => pclk,
 POUT   => pout, -- 7:0
 SND    => oSND,
 CTR1   => INP1,
 CTR2   => INP2,
 DSW    => "11000111", -- CC DDD VV S (Coinage, Dificultad,Vidas,Service Mode)
 AD     => AD
 );
----------------------------------------------------------------------------
-- Sync

iRGB <= pout(7 downto 6) & "00" & pout(5 downto 3) & '0' & pout(2 downto 0) & '0';

HVGEN : entity work.hvgen
port map(
	HPOS => hpos,
	VPOS => vpos,
	PCLK => pclk,
	iRGB => iRGB,
	oRGB => oRGB, -- 11:0 b,g,r
	HBLK => h_blank,
	VBLK => v_blank,
	HSYN => h_sync,
	VSYN => v_sync
);
-----------------------------------------------------------------
video_r_i <= oRGB(3 downto 0) & oRGB(3 downto 2);
video_g_i <= oRGB(7 downto 4) & oRGB(7 downto 6);
video_b_i <= oRGB(11 downto 8) & oRGB(11 downto 10);
-----------------------------------------------------------------
-- scan doubler

dblscan: entity work.scandoubler
	port map(
		clk_sys => clock_24,
		scanlines => "00",
		r_in   => video_r_i,
		g_in   => video_g_i,
		b_in   => video_b_i,
		hs_in  => h_sync,
		vs_in  => v_sync,
		r_out  => video_r,
		g_out  => video_g,
		b_out  => video_b,
		hs_out => O_HSYNC,
		vs_out => O_VSYNC
	);
-----------------------------------------------------------------------------
-- vga output

 O_VIDEO_R  <= video_r(5 downto 3);
 O_VIDEO_G  <= video_g(5 downto 3);
 O_VIDEO_B  <= video_b(5 downto 4);
--------------------------------------------------------------------------------------------
 -- Audio DAC
 
 audio <= oSND & "00000000";
 dac_in <= not audio(15) & audio(14 downto 0);
 
u_dac : entity work.dac
  generic map(
    msbi_g => 15
  )
port  map(
    clk_i   => clock_18,
    res_n_i => I_RESET,
    dac_i   => dac_in,
    dac_o   => audio_pwm
);

O_AUDIO_L <= audio_pwm; 
O_AUDIO_R <= audio_pwm;
------------------------------------------------------------------------------
-- get scancode from keyboard

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_9,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);
------------------------------------------------------------------------------
-- translate scancode to joystick

joystick : entity work.kbd_joystick
port map (
  clk         => clock_9,
  kbdint      => kbd_intr,
  kbdscancode => std_logic_vector(kbd_scancode), 
  joy_BBBBFRLDU  => joy_BBBBFRLDU 
);
------------------------------------------------------------------------------
-- debug

process(reset, clock_24)
begin
  if reset = '1' then
   clock_4hz <= '0';
   counter_clk <= (others => '0');
  else
    if rising_edge(clock_24) then
      if counter_clk = CLOCK_FREQ/8 then
        counter_clk <= (others => '0');
        clock_4hz <= not clock_4hz;
        led(7 downto 0) <= not AD(14 downto 7);
      else
        counter_clk <= counter_clk + 1;
      end if;
    end if;
  end if;
end process;
------------------------------------------------------------------------------
end struct;