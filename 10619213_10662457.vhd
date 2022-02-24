----------------------------------------------------------------------------------
-- Company: Politecnico di Milano   
-- Engineer: Regge Matteo, Rossi Nicolas
-- 
-- Create Date: 13.04.2021 10:46:18
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: ProgettoRL-20/21
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
port (
i_clk : in std_logic;
i_rst : in std_logic;
i_start : in std_logic;
i_data : in std_logic_vector(7 downto 0);
o_address : out std_logic_vector(15 downto 0);
o_done : out std_logic;
o_en : out std_logic;
o_we : out std_logic;
o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

        type state_type is(RST,ENREAD,WAITING,WAITING2,READ,PIXELNUM,ENREAD2,READ2,LOG,SHIFT,TEMP,DOSHIFT,DELTA,ENWRITE,WAITWR,WRITE,DONE,SUPERDONE);


        signal CurrState : state_type;
        signal log2 : integer;
	    signal count : integer;
	    signal dimX: std_logic_vector (7 downto 0);
	    signal dimY: std_logic_vector (7 downto 0);
	    signal numPixel :integer;
	    signal max_value: unsigned (7 downto 0);
	    signal min_value: unsigned (7 downto 0);
	    signal delta_value: unsigned (8 downto 0);
	    signal shift_value: integer;
	    signal count2 :integer;
	    signal count_shift :integer;
        signal write_count :integer;
        signal temp_pixel: std_logic_vector(8 downto 0); 
        
        
begin
	action:process(i_clk,i_rst)
	begin
	   if(i_rst = '1') then
	       --Reset signals inputs and outputs
			       log2<=0;
			       count<=0;
			       o_en<='0';
				   o_we<='0';
				   o_done<='0';	
				   shift_value<=0;
				   count2<=0;
				   count_shift<=0;
				   write_count <=0;	
				   
				   numPixel <= -1;	
				   max_value  <= "00000000";
				   min_value <= "11111111";	
				   o_address<="0000000000000000";--starting address
				   --add signals we are missing	ù
				   
				   CurrState <=RST;
	   elsif(rising_edge(i_clk)) then
		case CurrState is
			when RST =>
			
				if(i_start = '1') then
					CurrState <= ENREAD;
				else 	
					CurrState <= RST;	
				end if;
			when ENREAD=>
			         
			         o_en<='1';
				     o_we<='0';
				     
				    
				     
				     o_address <= std_logic_vector(to_unsigned(count,16));--check if working like intendend, if not move
				     if(numPixel = 1) then
				         CurrState <= DONE;
				     else
			             CurrState <= WAITING;
			         end if;
			when WAITING=>
			     
			     CurrState <= READ;
			     
			when READ=>
			     count <= count+1;
			     
				--Read dimensimos if first thing we read
				   if(count=0) then
				        dimY<=i_data;--check error found value not read/saved
				        
				   elsif(count=1) then    
				        dimX<=i_data;
				        
				   else --Otherwise find min and max
				     
				        if(max_value<unsigned(i_data)) then
				            max_value<=unsigned(i_data);--Check type maybe
				        else
				        end if;
				        if(min_value>unsigned(i_data)) then
				            min_value<=unsigned(i_data);--Check type maybe
				        else
				        end if;
				        
				   end if;  
				   if(count=1) then
				        CurrState <= PIXELNUM;

                   elsif(count=numPixel) then --we finished reading
				     o_address<="0000000000000000"; -- reset address for second reading
				     CurrState <= DELTA;
				  else --we didn't finish reading
				     CurrState <= ENREAD;
				  end if;
             when PIXELNUM =>
                   numPixel <= (to_integer(unsigned(dimX(7 downto 0)))*to_integer(unsigned(dimY(7 downto 0))))+1;
                   CurrState <= ENREAD;                   
		     when DELTA=>--we found max and min and calculate delta
		            
		           
		            o_en <= '0'; -- en at 0 when you do operation
		            delta_value<=("0" & (max_value-min_value))+1;
		            CurrState <=LOG;            
	
			 when LOG=>--Shift logico
			         		
				    if(unsigned(delta_value)/=1) then --Divide by 2 untill delta_value=1
				        delta_value<=("0"& delta_value(8 downto 1));
				        log2<=log2+1;
				        CurrState<=LOG;
				    else
				        CurrState <=SHIFT;
				    end if;
		    
 			when SHIFT=>--Number of shifts we apply to each Pixel 
 			        
 			        shift_value<=8-log2;
 			        CurrState<=ENREAD2;
 			
 			when DOSHIFT=>	
 			        
 			       if(unsigned(temp_pixel) < 255) then		   			 
 			             if(count_shift=shift_value) then
 			                count_shift <= 0;
 			              CurrState <= ENWRITE;
 			             else
 			                temp_pixel <= temp_pixel(7 downto 0) & "0"; -- shift to do on temp_pixel and not directly on mem2
 			                count_shift <= count_shift+1;
 			                
 			                CurrState <= DOSHIFT;
                         end if;
                    else
                        temp_pixel <="011111111";
                        count_shift <= 0;
                        CurrState <= ENWRITE;
                    end if;
            
            when ENREAD2 =>
                o_en<='1';
				o_we<='0';
				
				o_address <= std_logic_vector(to_unsigned(count2,16));
				CurrState <= WAITING2;
		    when WAITING2 =>
		         CurrState <= READ2;
 			when READ2=>
 			       
 			       if (count2 > 1) then 			           
 			           count2 <= count2 +1;
 			           CurrState <= TEMP;
 			       else 
 			           count2 <= count2 +1;
 			           CurrState <= ENREAD2;
 			        end if;
 			when TEMP => 
 			        o_en <= '0';
 			        
 			        temp_pixel <="0" & std_logic_vector(unsigned(i_data) - min_value);--calculates temp_pixel and converts in vector
 			        
 			        CurrState <= DOSHIFT;
 	
 			when ENWRITE=>
 			        
 			        o_en<='1';
				    o_we<='1';
				    o_address <= std_logic_vector(to_unsigned(count,16));
				    count <= count + 1;
				    CurrState<=WAITWR;
		     when WAITWR=>
		            CurrState<= WRITE;
			when WRITE=>
			    
			
				
				if(unsigned(temp_pixel) < 255) then
				    o_data <= temp_pixel(7 downto 0);
				else
				    o_data<=std_logic_vector(to_signed(255,8));
				end if;
			    write_count <= write_count + 1;	
				if(write_count = ((unsigned(dimX)*unsigned(dimY))- 1) ) then
				    CurrState <= DONE;
				else
				    CurrState <= ENREAD2;
				end if;
			when DONE=>
			    o_done <= '1';
			    CurrState <= SUPERDONE;
				--Finished!							
			when SUPERDONE=>
			    if(i_start = '0') then
			         o_done <='0';
			         count <= 0;
			         log2<=0;
			         o_en<='0';
				     o_we<='0';	
				     shift_value<=0;
				     count2<=0;
				     count_shift<=0;
				     write_count <=0;		
				     numPixel <= -1;
				     max_value  <= "00000000";
				     min_value <= "11111111";	
				     o_address<="0000000000000000";--starting address
			         CurrState <= RST;
			    else 
			        CurrState <= SUPERDONE;    
			    end if;
			    	
		end case;
	   end if;	
	end process;
end Behavioral;