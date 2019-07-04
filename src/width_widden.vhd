----------------------------------------------------------------------------------
-- Company: BSC
-- Engineer: LEDOUX Louis
-- 
-- Create Date: 02/28/2019 05:47:29 PM
-- Design Name: 
-- Module Name: width_widden - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--  LQUI help
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity width_widden is
    generic (
        -- 
        DATAi_W                 : integer := 32;  --I/F DUT (default is 32-it)
          
        DATAo_W                 : integer := 64  --I/F Tx buffer (ddfault is 64-bit)
        --DATAo_B                 : integer := 6    --Bit
        );
    port (
        -- System
        clk                     : in  std_logic;
        rst_n                   : in  std_logic;
        
        -- DUT I/F
        rtr_o                   : out std_logic;
        rts_i                   : in  std_logic;          
        sow_i                   : in  std_logic;
        eow_i                   : in  std_logic;
        data_i                  : in  std_logic_vector (DATAi_W-1 DOWNTO 0);
          
        --Tx buffer I/F
        rtr_i                    : in  std_logic;    
        rts_o                    : out std_logic;    
        sow_o                    : out std_logic;
        eow_o                    : out std_logic;
        oerr                    : out std_logic;
        --onobit                  : out std_ulogic_vector (DATAo_B-1 DOWNTO 0);
        data_o                  : out std_logic_vector (DATAo_W-1 DOWNTO 0)
        );
end width_widden;

architecture rtl of width_widden is
    
    -- parameters
    
    --constant ETHTYPE_IPv4       : std_ulogic_vector (15 DOWNTO 0 ):=X"0800";  
 
    --Pipeline
    signal rts_i1               : std_logic;
    signal sow_i1               : std_logic;
    signal eow_i1               : std_logic;
    signal data_i1              : std_logic_vector (DATAi_W-1 downto 0);
     
    signal ibus                 : std_logic_vector (DATAi_W+2 downto 0);
    signal ibus1                : std_logic_vector (DATAi_W+2 downto 0);
     
    --Shift data
    signal shdat                : std_logic_vector (DATAi_W-1 downto 0);
    signal shphase              : std_logic;
    signal sow_i1_lat           : std_logic;
     
    --Read data fifo     
    signal vld                  : std_logic;
    signal sow                  : std_logic;
    signal eow                  : std_logic;
    --signal nobit                : std_ulogic_vector (DATAo_B-1 downto 0);
    signal data                 : std_logic_vector (DATAo_W-1 downto 0);
    signal err                  : std_logic;
    
    --signal obus                 : std_ulogic_vector (DATAo_W+DATAo_B+3 downto 0);
    --signal obus1                : std_ulogic_vector (DATAo_W+DATAo_B+3 downto 0);
    
    signal obus                 : std_logic_vector (DATAo_W+3 downto 0);
    signal obus1                : std_logic_vector (DATAo_W+3 downto 0);

begin


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Pipeline

ibus <= (rts_i & sow_i & eow_i & data_i);

ibus_pp: entity work.pkt_fflopx
    generic map (DAT_W => 3+DATAi_W)
    port map (
        clk     => clk, 
        rst_n   => rst_n,
        din     => ibus, 
        dout    => ibus1
        );
                  
rts_i1 <= ibus1(DATAi_W+2);                  
sow_i1 <= ibus1(DATAi_W+1);
eow_i1 <= ibus1(DATAi_W);
data_i1 <= ibus1(DATAi_W-1 downto 0);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- shift data

process(clk, rst_n)
    begin
    if rst_n = '0' then
        shdat <= (others => '0');
    elsif rising_edge(clk) then
        if (rts_i1 = '1') then
            shdat <= data_i1;
        end if;
    end if;
end process;

process(clk, rst_n)
    begin
    if rst_n = '0' then
        shphase <= '0';
    elsif rising_edge(clk) then
        if (rts_i1 = '1') then
            if (sow_i1 = '1') then shphase <= '1';
            elsif (eow_i1 = '1') then shphase <= '0';
            else shphase <= not shphase;
            end if;
        end if;
    end if;
end process;

process(clk, rst_n)
    begin
    if rst_n = '0' then
        sow_i1_lat <= '0';
    elsif rising_edge(clk) then
        if (rts_i1 = '1') then
            sow_i1_lat <= sow_i1;
        end if;
    end if;
end process;

vld <= rts_i1 and (shphase or eow_i1);
sow <= rts_i1 and sow_i1_lat;
eow <= rts_i1 and eow_i1;
--nobit <= "111111" when (shphase = '1') else "011111";
err <= '0';
data <= (shdat & data_i1) when (shphase = '1') else (data_i1 & x"0");

--obus <= vld & sow & eow & nobit & err & data;
obus <= vld & sow & eow & err & data;

--obus_pp: entity work.pkt_fflopx
--    generic map (DAT_W => DATAo_W+DATAo_B+4)
--    port map (
--        clk     => clk, 
--        rst_n   => rst_n,
--        din     => obus, 
--        dout    => obus1
--        );

obus_pp: entity work.pkt_fflopx
    generic map (DAT_W => DATAo_W+4)
    port map (
        clk     => clk, 
        rst_n   => rst_n,
        din     => obus, 
        dout    => obus1
        );

--rts_o <= obus1(DATAo_W+DATAo_B+3);
--sow_o <= obus1(DATAo_W+DATAo_B+2);
--eow_o <= obus1(DATAo_W+DATAo_B+1);
--onobit <= obus1(DATAo_W+DATAo_B downto DATAo_W+1);
rts_o <= obus1(DATAo_W+3);
sow_o <= obus1(DATAo_W+2);
eow_o <= obus1(DATAo_W+1);
oerr <= obus1(DATAo_W);
data_o <= obus1(DATAo_W-1 downto 0);
                  
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
rtr_o <= rtr_i;

end rtl;