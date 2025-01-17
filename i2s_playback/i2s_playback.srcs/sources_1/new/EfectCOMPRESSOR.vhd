----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Eros Garc�a Arroyo
-- 
-- Create Date: 09.11.2019 23:04:06
-- Design Name: 
-- Module Name: EfectCOMPRESSOR - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: Si la ganancia de la se�al de entrada supera el umbral se amplifica por un valor peque�o,
--               sino, se ampifica por un valor mayor
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity EfectCOMPRESSOR is
GENERIC(
    d_width         : INTEGER := 16 --Ancho del bus 
    );
Port ( 
    clk                   : in STD_LOGIC; --MCLK                                             
    reset_n               : in STD_LOGIC; --Reset as�ncrono a nivel alto del sistema global  
    enable_in             : IN STD_LOGIC; --Enable proporcionado por el i2s2                 
    l_data_in             : in STD_LOGIC_VECTOR (d_width-1  downto 0); -- STD_LOGIC -> Datos de entrada izquierdos;                    
    l_data_out            : out STD_LOGIC_VECTOR (d_width-1  downto 0); -- STD_LOGIC -> Datos de salida izquierdos;                    
    r_data_in             : in STD_LOGIC_VECTOR (d_width-1  downto 0); -- STD_LOGIC -> Datos de entrada derechos;                      
    r_data_out            : out STD_LOGIC_VECTOR (d_width-1  downto 0); -- STD_LOGIC -> Datos de salida derechos;                      
    enable_out            : out STD_LOGIC --Enable out para la se�al i2s2
);
end EfectCOMPRESSOR;

architecture Behavioral of EfectCOMPRESSOR is

signal l_data_in_reg, l_data_in_next, r_data_in_reg, r_data_in_next: signed (d_width-1  downto 0);
signal l_data_out_aux, r_data_out_aux: signed ((d_width*3/2-1) downto 0);
signal Vth_negative : signed (d_width-1  downto 0) := "1001111111111111"; --Umbral de la zona no l�neal negativa
signal Vth_positive : signed (d_width-1  downto 0) := "0110000000000000"; --Umbral de la zona no lineal positiva
signal g1 : signed ((d_width/2 - 1) downto 0) := "01010000"; --Ganancia para zona lineal
signal g2 : signed ((d_width/2 - 1) downto 0) := "00010000"; --Ganancia para zona no lineal
    
begin 

--State register
process(clk, reset_n, enable_in)
begin
    if(reset_n = '1') then
        l_data_in_reg <= (others => '0');
        r_data_in_reg <= (others => '0');
    elsif (rising_edge(clk)) then --MCLK
        if(enable_in = '1')then
            l_data_in_reg <= l_data_in_next;
            r_data_in_reg <= r_data_in_next;
        end if;
    end if;  
end process;

--Next state
process(clk, reset_n, enable_in, l_data_in, r_data_in, enable_in, l_data_in_reg, r_data_in_reg, Vth_positive, Vth_negative, g1, g2)
begin
    if reset_n = '1' then
        l_data_out_aux <= (others => '0');
        r_data_out_aux <= (others => '0');
        enable_out <= '0';
    elsif (rising_edge(clk)) then --MCLK
        enable_out <= enable_in;
        if(enable_in = '1')then
            l_data_in_next <= signed(l_data_in);
            r_data_in_next <= signed(r_data_in);
            if((0 <= l_data_in_reg) and (l_data_in_reg < Vth_positive)) then
                l_data_out_aux <= l_data_in_reg*g1;
                
            elsif(l_data_in_reg >= Vth_positive) then
                l_data_out_aux <= (Vth_positive*g1) + ((l_data_in_reg - Vth_positive)*g2);
                
            elsif((l_data_in_reg > Vth_negative) and (l_data_in_reg < 0))then
                l_data_out_aux <= l_data_in_reg*g1;
                
            elsif(l_data_in_reg <= Vth_negative) then
                l_data_out_aux <= (Vth_negative*g1) + ((l_data_in_reg - Vth_negative)*g2);
                
            end if;
            
            if((0 <= r_data_in_reg) and (r_data_in_reg < Vth_positive))then
                r_data_out_aux <= r_data_in_reg*g1;
                
            elsif(r_data_in_reg > Vth_positive) then
                r_data_out_aux <= (Vth_positive*g1) + ((r_data_in_reg - Vth_positive)*g2);
                
            elsif((r_data_in_reg > Vth_negative) and (r_data_in_reg < 0))then
                r_data_out_aux <= r_data_in_reg*g1;
                
            elsif(r_data_in_reg <= Vth_negative) then
                r_data_out_aux <= (Vth_negative*g1) + ((r_data_in_reg - Vth_negative)*g2);
            end if;
        end if;
    end if;  
end process; 

--Output logic --> Hay que castear la se�al ya que por las multiplicaciones hay que subirla a 32 bits,
               --  Nos quedamos con el signo y los decimales m�s significativos.
l_data_out <= STD_LOGIC_VECTOR(l_data_out_aux((d_width*3/2)-2 downto d_width/2-1));   
r_data_out <= STD_LOGIC_VECTOR(r_data_out_aux((d_width*3/2)-2 downto d_width/2-1));  

end Behavioral;
