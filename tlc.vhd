LIBRARY IEEE;
USE ieee.std_logic_1164.all;
ENTITY tlc IS
	PORT ( CLOCK_50 : IN std_logic;
				KEY : IN std_logic_vector(1 DOWNTO 0);
				LEDS : OUT std_logic_vector(5 DOWNTO 0);
				HEX0, HEX1 : OUT STD_LOGIC_VECTOR(0 TO 6) );
END tlc;

ARCHITECTURE behaviour OF tlc IS
	COMPONENT FSM
		PORT (clock, reset, request : IN STD_LOGIC;
			timer1, timer0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0) ;
				 req_status, state_event: OUT STD_LOGIC;
				 state_time : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
				 state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) );
	END COMPONENT ;
	COMPONENT counter IS
		GENERIC ( n : NATURAL := 4; k : INTEGER := 16 ); 
		PORT ( clock, reset, enable, load: IN STD_LOGIC;
					start_time : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
					count : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
					rollover : OUT STD_LOGIC );
	END COMPONENT;
	COMPONENT bcd7seg
		PORT ( BCD : IN STD_LOGIC_VECTOR(3 DOWNTO 0) ; 
				state : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
				HEX : OUT STD_LOGIC_VECTOR(0 TO 6) ) ; 
	END COMPONENT ;
	COMPONENT light
		PORT ( status : IN STD_LOGIC ;
				state : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ;
				LED : OUT STD_LOGIC_VECTOR(5 DOWNTO 0) ) ;
	END COMPONENT;

SIGNAL one_second : STD_LOGIC;
SIGNAL state_event : STD_LOGIC;
SIGNAL request_status : STD_LOGIC;
SIGNAL state : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL state_time : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL BCD1, BCD0 : STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL roll : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN
	states: FSM 
		PORT MAP (clock => CLOCK_50, reset => KEY(0), request => KEY(1),timer1 => BCD1, 
					timer0 => BCD0,req_status => request_status, state_event => state_event, 
					state_time => state_time, state => state) ; 
	slow_clock: counter
		GENERIC MAP ( n => 27, k => 50000000 ) 
		PORT MAP ( clock => CLOCK_50, reset => KEY(0), enable => '1', load 
		=> state_event, start_time => (OTHERS => '0'), rollover => one_second );				
	ones: counter 
		GENERIC MAP ( n => 4, k => 10 ) 
		PORT MAP ( clock => CLOCK_50, reset => KEY(0), enable => one_second, load => state_event, 
			start_time => state_time(3 DOWNTO 0), count => BCD0, rollover => roll(0) ); 
	tens: counter
			GENERIC MAP ( n => 4, k => 10)
			PORT MAP ( clock => CLOCK_50, reset => KEY(0), enable => one_second AND roll(0), 
			load => state_event, start_time => state_time(7 DOWNTO 4), count => BCD1 ); 
	digit0: bcd7seg 
		PORT MAP (BCD => BCD0, state => state, HEX => HEX0) ; 
	digit1: bcd7seg 
		PORT MAP(BCD => BCD1, state => state, HEX => HEX1) ;
	lights: light 
		PORT MAP(status => request_status, state => state, LED => LEDS) ;
END behaviour ;				
					
LIBRARY ieee;
USE ieee.std_logic_1164.all;
ENTITY bcd7seg IS
	PORT ( BCD : IN STD_LOGIC_VECTOR(3 DOWNTO 0) ;
		state : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ;
		HEX : OUT STD_LOGIC_VECTOR(0 TO 6) ) ;
END ENTITY;

ARCHITECTURE behaviour OF bcd7seg IS
	BEGIN
	HEX <= "1111110" WHEN (state = "00") ELSE -- “stand-by” when G
				"0000001" WHEN (BCD = "0000") ELSE -- 0
				"1001111" WHEN (BCD = "0001") ELSE -- 1
				"0010010" WHEN (BCD = "0010") ELSE -- 2
				"0000110" WHEN (BCD = "0011") ELSE -- 3
				"1001100" WHEN (BCD = "0100") ELSE -- 4
				"0100100" WHEN (BCD = "0101") ELSE -- 5
				"1100000" WHEN (BCD = "0110") ELSE -- 6
				"0001111" WHEN (BCD = "0111") ELSE -- 7
				"0000000" WHEN (BCD = "1000") ELSE -- 8
				"0001100" WHEN (BCD = "1001") ELSE -- 9
				"1111111";
END behaviour;

LIBRARY IEEE;
USE ieee.std_logic_1164.all;
ENTITY light IS
	PORT ( status : IN STD_LOGIC;
		state : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ;
		LED : OUT STD_LOGIC_VECTOR(5 DOWNTO 0) ) ;
END ENTITY;
			
ARCHITECTURE behaviour OF light IS
	BEGIN
		LED(5) <= status; 
		LED(4 DOWNTO 0) <= "10001" WHEN state = "00" ELSE 
								 "10010" WHEN state = "01" ELSE 
								 "01100" WHEN state = "10" ELSE 
								 "10001" WHEN state = "11" ELSE 
								 "10001";
END behaviour;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL; 
use ieee.std_logic_arith.ALL; 
ENTITY counter IS
	GENERIC ( n : NATURAL := 4; k : INTEGER := 15 );
	PORT ( clock, reset，enable, load : IN STD_LOGIC;
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
ENTITY FSM IS
	PORT ( clock, reset， request : IN STD_LOGIC;
			timer1, timer0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0) ;
			req_status，state_event : OUT STD_LOGIC;
			state_time : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) );
END FSM;

ARCHITECTURE behaviour OF FSM IS 
	SIGNAL st_event : STD_LOGIC := '0'; 
	SIGNAL status : STD_LOGIC ; 
	SIGNAL state_s : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00"; 
	SIGNAL st_time : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
	PROCESS (clock, reset, request)
		VARIABLE second_req : STD_LOGIC := '0'; 
		BEGIN
		IF reset = '0' THEN
			state_s <= "00"; 
			second_req := '0';
			status <= '0';
		ELSIF clock'EVENT AND clock = '1' THEN
			CASE state_s IS
				WHEN "00"=> -- G
					IF request = '0' OR second_req ='1' THEN 
						state_s <= "01"; 
						st_time <= "00000110"; 
						st_event <= '1';
						second_req := '0';
						status <= '1'; 
					END IF;
				WHEN "01"=> -- Y
					IF timer1 & timer0 = "10011001" THEN 
						state_s <= "10"; 
						st_time <= "00010001"; 
						st_event <= '1';
						status <= '0';
					ELSE
						st_event <= '0';
					END IF;
				WHEN "10"=> -- R
					IF timer1 & timer0 = "10011001" THEN
						state_s <= "11"; 
						st_time <= "00010001"; 
						st_event <= '1';
					ELSE
						st_event <= '0';
					END IF;
				WHEN "11"=> -- G1
					IF timer1 & timer0 = "10011001" THEN
						state_s <= "00"; 
						st_time <= "00010001";
						st_event <= '1';
					ELSIF request = '0' THEN 
						second_req := '1'; 
						status <= '1';
					ELSE
						st_event <= '0';
					END IF;
			END CASE;
		END IF; 
	END PROCESS;
		state <= state_s; 
		state_time <= st_time;
		state_event <= st_event;
		req_status <= status;
END behaviour;	
		