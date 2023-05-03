-- uart_rx_fsm.vhd: UART controller - finite state machine controlling RX side
-- Author(s): Dominik Horut (xhorut01)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity UART_RX_FSM is
    port(
       CLK : in std_logic;
       RST : in std_logic;
       DIN : in std_logic;
       READ_FINISHED : in std_logic;
       CNT_CLK : in std_logic_vector( 4 downto 0);
       CNT_BIT : in std_logic_vector( 3 downto 0);
       CNT_CLK_EN : out std_logic;
       READING : out std_logic;
       IS_VALID : out std_logic
       );
end entity;



architecture behavioral of UART_RX_FSM is
type STATE_TYPE is (START_BIT, FIRST_BIT, READ_DATA, STOP_BIT, VALID_SIG); -- stavy
signal state : STATE_TYPE := START_BIT; -- pocatecni stav nastvime na START_BIT
begin

    READING <= '1' when state = READ_DATA else '0'; -- pokud se nachazime ve stavu READ_DATA, nastavime READING na 1
    CNT_CLK_EN <= '1' when state = FIRST_BIT or state = READ_DATA or state = STOP_BIT else '0'; -- pokud jsme ve stavech FIRST_BIT, READ_DATA nebo STOP_BIT, 
                                                                                                -- zapneme counter hodinovych cyklu
    IS_VALID <= '1' when state = VALID_SIG else '0'; -- pokud se dostaneme do stavu VALID_SIG (prenos probehl uspesne), nastavime IS_VALID na 1

    process (CLK) begin 
        if rising_edge(CLK) then -- pokud jsme na vzestupne hrane
            if RST = '1' then
                state <= START_BIT;
            else
            case state is
                when START_BIT => 
                if DIN = '0' then -- pokud je DIN jedna, pokracujeme na stav FIRST_BIT
                    state <= FIRST_BIT;
                    end if;
                
                when FIRST_BIT => if CNT_CLK = "10110" then  -- cekame 22 hodinovych cyklu (dostaneme se do mid bitu prvniho bitu) a pokracujeme do stavu READ_DATA
                    state <= READ_DATA;
                    end if;
                
                when READ_DATA => 
                if READ_FINISHED = '1' then -- pokud jsme precetli 8 bitu (READ_FINISHED == 1) pokracujeme do stavu STOP_BIT, jinak pokracujeme ve cteni 
                    state <= STOP_BIT;
                    else
                    state <= READ_DATA;
                    end if;

                when STOP_BIT => 
                if CNT_CLK = "10000" then -- cekame 16 hodinovych cyklu (prenos je uspesny) a pokracujeme do stavu VALID_SIG
                    state <= VALID_SIG;
                    end if;
                
                when VALID_SIG => 
                state <= START_BIT; -- pokracujeme opet na pocatecni stav START_BIT

                when others => null; -- v pripade jineho (nezadouciho) stavu NULL
                end case;
            end if;
        end if;
    end process;


end architecture;
