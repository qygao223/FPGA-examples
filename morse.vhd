LIBRARY IEEE;
USE ieee.std_logic_1164.all;

ENTITY morse is
    PORT (CLK : IN std_logic;
          KEY : IN std_logic_vector(1 DOWNTO 0);
          SW : IN std_logic_vector(2 DOWNTO 0);
          LEDS : OUT std_logic);
END morse;

ARCHITECTURE behaviour OF morse is
    COMPONENT FSM
        PORT (clock, reset, request: IN STD_LOGIC;
            dec_length : IN INTEGER range 0 to 4;
            morse : IN STD_LOGIC_VECTOR(3 DOWNTO 0) ;
            timer0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0) ;
            state_event : OUT STD_LOGIC;
            state_time : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) );
    END COMPONENT;
    COMPONENT counter is
        GENERIC ( n : NATURAL := 4; k : INTEGER := 16 );
        PORT ( clock, reset, enable, load : IN STD_LOGIC;
            start_time : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            count : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            rollover : OUT STD_LOGIC );
    END COMPONENT;
    COMPONENT light
        PORT (state : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ;
              LEDin : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
              LEDout : OUT STD_LOGIC ) ;
    END COMPONENT;
    COMPONENT selection
        PORT (SW_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
              reset,clock : IN STD_LOGIC;
              dec_length : OUT INTEGER range 0 to 4;
              morse : OUT STD_LOGIC_VECTOR(3 DOWNTO 0));
    END COMPONENT;

    SIGNAL state_event : STD_LOGIC ;
    SIGNAL state : STD_LOGIC_VECTOR(1 DOWNTO 0) ;
    SIGNAL state_time : STD_LOGIC_VECTOR(3 DOWNTO 0) ;
    SIGNAL LED0 : STD_LOGIC_VECTOR(3 DOWNTO 0) ;
    SIGNAL one_second : STD_LOGIC ;
    SIGNAL lengthin : integer range 0 to 4 ;
    SIGNAL morsein : STD_LOGIC_VECTOR(3 DOWNTO 0) ;

    BEGIN
		states: FSM
			PORT MAP (clock => CLK, reset => KEY(0), request => KEY(1),
							dec_length => lengthin, morse => morsein, timer0 => LED0,
							state_event => state_event, state_time => state_time, state => state) ;
		slow_clk: counter
			GENERIC MAP ( n => 25, k => 25000000 )
			PORT MAP (clock => CLK, reset => KEY(0), enable => '1', load => state_event, 
							start_time => (OTHERS => '0'), rollover => one_second );
		half: counter
			GENERIC MAP ( n => 4, k => 10 )
			PORT MAP ( clock => CLK, reset => KEY(0), enable => one_second, load => state_event,
							start_time => state_time(3 DOWNTO 0), count => LED0);
	  lighting: light
			PORT MAP(state => state, LEDin => LED0, LEDout => LEDS);
	  morse_selection : selection
			PORT MAP (clock => CLK, reset => KEY(0), SW_in => SW, morse => morsein, dec_length => lengthin);
END behaviour;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL; 
use ieee.std_logic_arith.ALL;
ENTITY counter IS
	GENERIC ( n : NATURAL := 4; k : INTEGER := 16 );
	PORT ( clock, reset, enable, load : IN STD_LOGIC;
			 start_time : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			 count : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			 rollover : OUT STD_LOGIC );
END ENTITY;

ARCHITECTURE behaviour OF counter IS
SIGNAL count_s : STD_LOGIC_VECTOR(n-1 DOWNTO 0) ;
	BEGIN
		PROCESS(clock, reset)
		BEGIN
		IF (reset = '0') THEN
		count_s <= start_time; 
		ELSIF load = '1' THEN
		count_s <= start_time;
		ELSIF ((clock'event) and (clock = '1')) THEN
			IF (enable = '1') THEN
				IF (count_s = 0) THEN
				count_s <= conv_std_logic_vector(k-1, n);
				ELSE
				count_s <= count_s - 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	count <= count_s;
	rollover <= '1' WHEN (count_s = 0) ELSE '0'; 
END behaviour;

LIBRARY IEEE;
USE ieee.std_logic_1164.all;
ENTITY light IS
    PORT (state : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ;
        LEDin : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        LEDout : OUT STD_LOGIC ) ;
END light;

ARCHITECTURE behaviour OF light is
    BEGIN
        LEDout <= '0' WHEN (state = "00") ELSE
                  '0' WHEN (LEDin = "0001") ELSE
                  '1' WHEN (LEDin = "0010") ELSE
						'1' WHEN (LEDin = "0011") ELSE
						'1' WHEN (LEDin = "0100") ELSE
						'0';
END behaviour;

LIBRARY IEEE;
USE ieee.std_logic_1164.all;
ENTITY selection IS
    PORT (SW_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            reset,clock : IN STD_LOGIC;
            dec_length : OUT INTEGER range 0 to 4;
            morse : OUT STD_LOGIC_VECTOR(3 DOWNTO 0));
END selection;

ARCHITECTURE behaviour OF selection IS
	BEGIN
	process (SW_in, reset,clock)
	BEGIN
		IF reset = '0' THEN
		dec_length <= 0;
		morse <= "0000";
		ELSIF clock'EVENT AND clock = '1' THEN
		 CASE SW_in is
			  WHEN "000"=>
					dec_length <= 2;
					morse <= "0100";
			  WHEN "001"=>
					dec_length <= 4;
					morse <= "0111";
			  WHEN "010"=>
					dec_length <= 4;
					morse <= "1010";
			  WHEN "011"=>
					dec_length <= 3;
					morse <= "0111";
			  WHEN "100"=>
					dec_length <= 1;
					morse <= "0000";
			  WHEN "101"=>
					dec_length <= 4;
					morse <= "0010";
			  WHEN "110"=>
					dec_length <= 3;
					morse <= "1100";
			  WHEN "111"=>
					dec_length <= 4;
					morse <= "0000";
		 END CASE;
		END IF;
	END process;
END behaviour;

LIBRARY IEEE;
USE ieee.std_logic_1164.all;
ENTITY FSM is
    PORT (request, clock, reset : IN STD_LOGIC;
        dec_length : IN INTEGER range 0 to 4;
        morse : IN STD_LOGIC_VECTOR(3 DOWNTO 0) ;
        timer0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0) ;
		  length_FSM : BUFFER INTEGER range 0 to 4;
		  morse_FSM : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0);
        state_event : OUT STD_LOGIC;
        state_time : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) );
END FSM;

ARCHITECTURE behaviour OF FSM IS
    SIGNAL st_event : STD_LOGIC := '0';
    SIGNAL state_s : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    SIGNAL st_time : STD_LOGIC_VECTOR(3 DOWNTO 0);
    BEGIN
		PROCESS (clock, reset, request)
			BEGIN
			IF reset = '0' THEN
				 state_s <= "00";
				 st_event <= '0';
			ELSIF clock'EVENT AND clock = '1' THEN
			  CASE state_s IS
					WHEN "00"=>
						IF request = '0' THEN
							length_FSM <= dec_length;
							morse_FSM <= morse;
							state_s <= "11";
						END IF;
					WHEN "01" | "10"=>
						 IF timer0 = "1001" THEN
							  length_FSM <= length_FSM -1;
							  morse_FSM(3) <= morse_FSM(2);
							  morse_FSM(2) <= morse_FSM(1);
							  morse_FSM(1) <= morse_FSM(0);
							  morse_FSM(0) <= '0' ;
							  state_s <= "11";
							  st_event <= '0';
						 ELSE
							  st_event <= '0';
						 END IF;
					WHEN "11"=>
						IF length_FSM > 0 THEN
							IF morse_FSM(3) = '1' THEN
							st_time <= "0101";
							st_event <= '1';
							state_s <= "10";
							ELSIF morse_FSM(3) = '0' THEN
							st_time <= "0011";
							st_event <= '1';
							state_s <= "01";
							END IF;
						ELSE
							state_s<="00";
							st_event <= '0';
						END IF;
			  END CASE;
			END IF;
		END PROCESS;        
		state <= state_s;
		state_time <= st_time;
		state_event <= st_event;
END behaviour;