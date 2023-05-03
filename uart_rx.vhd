-- uart_rx.vhd: UART controller - receiving (RX) side
-- Author(s): Dominik Horut (xhorut01)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

--navic
use ieee.numeric_std.all;


-- Entity declaration (DO NOT ALTER THIS PART!)
entity UART_RX is
    port(
        CLK      : in std_logic;
        RST      : in std_logic;
        DIN      : in std_logic;
        DOUT     : out std_logic_vector(7 downto 0);
        DOUT_VLD : out std_logic
    );
end entity;



-- Architecture implementation (INSERT YOUR IMPLEMENTATION HERE)
architecture behavioral of UART_RX is
   signal CNT_CLK : std_logic_vector( 4 downto 0); -- counter hodinoveho signalu 
   signal CNT_BIT : std_logic_vector( 3 downto 0); -- counter prenesenych bitu (0 az 8)          
   signal READING : std_logic;                     -- nastaven na 1 pokud se nachazime ve stavu READ_DATA, jinak 0
   signal CNT_CLK_EN : std_logic;                  -- pro zajisteni, aby counter pocital jen ve stavech FIRST_BIT, READ_DATA a STOP_BIT
   signal IS_VALID : std_logic;                    -- nastaven na 1 pokud prenos probehne v poradku (dostaneme se do stavu VALID_SIG)

   begin                          

    -- Instance of RX FSM
    fsm: entity work.UART_RX_FSM
    port map (
        CLK => CLK,
        RST => RST,
        DIN => DIN,
        CNT_CLK => CNT_CLK,
        CNT_BIT => CNT_BIT,
        CNT_CLK_EN => CNT_CLK_EN,
        READING => READING,
        READ_FINISHED => CNT_BIT(3), -- az bude CNT_BIT == 8 (1000), nastavi se na 1 
        IS_VALID => IS_VALID

        
    );
    DOUT_VLD <= IS_VALID;

    process(CLK) begin
        if rising_edge(CLK) then 
           if RST = '1' then              -- pri resetu se obe pocitadla i DOUT vynuluji
            DOUT <= "00000000";
            CNT_CLK <= "00000"; 
            CNT_BIT <= "0000";
            else
                if CNT_CLK_EN = '1' then  -- nachazime se ve stavech FIRST_BIT, READ_DATA nebo STOP_BIT a pocitame hodinove cykly
                    CNT_CLK <= CNT_CLK +1; 
                else
                    CNT_CLK <= "00000";   -- nachazime se ve stavu kdy neni potreba hodinove cykly pocitat, counter se vynuluje
                end if;

                if READING = '1' and (CNT_CLK >= "10000") then  -- pokud jsme ve stavu READ_DATA a dojdeme do mid bitu (CNT_CLK == 16)
                    DOUT(to_integer(unsigned(CNT_BIT))) <= DIN; -- prevedeme dany bit na DOUT
                    CNT_BIT <= CNT_BIT + 1;                     -- inkrementujeme pocet prenesenych bitu
                    CNT_CLK <= "00001";                         -- counter hodinovych cyklu opet nastavime na 1 a cekame na mid bit
                end if;

                if READING = '0' then     -- nejsme ve stavu READ_DATA
                    CNT_BIT <= "0000";    -- counter prenesenych bitu proto vynulujeme
                end if;    
            end if;
        end if;
    end process;


   

end architecture;
