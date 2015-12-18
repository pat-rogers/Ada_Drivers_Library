------------------------------------------------------------------------------
--                                                                          --
--                    Copyright (C) 2015, AdaCore                           --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of STMicroelectronics nor the names of its       --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
--                                                                          --
--  This file is based on:                                                  --
--                                                                          --
--   @file    stm32f407xx.h   et al.                                        --
--   @author  MCD Application Team                                          --
--   @version V1.1.0                                                        --
--   @date    19-June-2014                                                  --
--   @brief   CMSIS STM32F407xx Device Peripheral Access Layer Header File. --
--                                                                          --
--   COPYRIGHT(c) 2014 STMicroelectronics                                   --
------------------------------------------------------------------------------

--  This file provides register definitions for the STM32F4 (ARM Cortex M4F)
--  microcontrollers from ST Microelectronics.

package body STM32.SYSCFG is

   procedure Connect_External_Interrupt
     (Port : GPIO_Port;
      Pin  : GPIO_Pin_Index)
   is
      CR_Index   : Integer range EXTI_Control_Registers'Range;
      EXTI_Index : Integer range EXTI_n_List'Range;
      Port_Name  : constant GPIO_Port_Id := As_GPIO_Port_Id (Port);
   begin
      --  First we find the control register, of the four possible, that
      --  contains the EXTI_n value for pin 'n' specified by the Pin parameter.
      --  In effect, this is what we are doing for the EXTICR index:
      --    case GPIO_Pin'Pos (Pin) is
      --       when  0 .. 3  => CR_Index := 0;
      --       when  4 .. 7  => CR_Index := 1;
      --       when  8 .. 11 => CR_Index := 2;
      --       when 12 .. 15 => CR_Index := 3;
      --    end case;
      --  Note that that means we are dependent upon the order of the Pin
      --  declarations because we require GPIO_Pin'Pos(Pin_n) to be 'n', ie
      --  Pin_0 should be at position 0, Pin_1 at position 1, and so forth.
      CR_Index := Pin / 4;

      --  Now we must find which EXTI_n value to use, of the four possible,
      --  within the control register. We are depending on the GPIO_Port type
      --  being an enumeration and that the enumeral order is alphabetical on
      --  the Port letter, such that in effect GPIO_A'Pos = 0, GPIO_B'Pos = 1,
      --  and so on.
      EXTI_Index := GPIO_Port_Id'Pos (Port_Name) mod 4;  -- ie 0 .. 3

      --  Finally we assign the port 'number' to the EXTI_n value within the
      --  control register. We depend upon the Port enumerals' underlying
      --  numeric representation values matching what the hardware expects,
      --  that is, the values 0 .. n-1, which we get automatically unless
      --  overridden.

      SYSCFG.EXTICR (CR_Index).EXTI (EXTI_Index) := Port_Name;
   end Connect_External_Interrupt;

     --------------------------------
   -- Connect_External_Interrupt --
   --------------------------------

   procedure Connect_External_Interrupt
     (Port : GPIO_Port;
      Pin  : GPIO_Pin)
   is
   begin
      Connect_External_Interrupt (Port, GPIO_Pin'Pos (Pin));
   end Connect_External_Interrupt;

   --------------------------------
   -- Connect_External_Interrupt --
   --------------------------------

   procedure Connect_External_Interrupt
     (Point  : GPIO_Point)
   is
   begin
      Connect_External_Interrupt (Point.Port.all, Point.Pin);
   end Connect_External_Interrupt;

   --------------------------------
   -- Connect_External_Interrupt --
   --------------------------------

   procedure Connect_External_Interrupt
     (Port : GPIO_Port;
      Pins : GPIO_Pins)
   is
   begin
      for Pin of Pins loop
         Connect_External_Interrupt (Port, Pin);
      end loop;
   end Connect_External_Interrupt;

   --------------------------
   -- Set_External_Trigger --
   --------------------------

   procedure Set_External_Trigger
     (Pin     : GPIO_Pin;
      Trigger : External_Triggers)
   is
      This_Pin : constant GPIO_Pin_Index := GPIO_Pin'Pos (Pin);
   begin
      Set_External_Trigger (This_Pin, Trigger);
   end Set_External_Trigger;

   procedure Set_External_Trigger
     (Pin     : GPIO_Pin_Index;
      Trigger : External_Triggers)
   is
   begin
      EXTI.IMR (Pin) := Trigger in Interrupt_Triggers;
      EXTI.EMR (Pin) := Trigger in Event_Triggers;
   end Set_External_Trigger;

   --------------------------
   -- Set_External_Trigger --
   --------------------------

   procedure Set_External_Trigger
     (Pins    : GPIO_Pins;
      Trigger : External_Triggers)
   is
   begin
      for Pin of Pins loop
         Set_External_Trigger (Pin, Trigger);
      end loop;
   end Set_External_Trigger;

   -------------------------
   -- Select_Trigger_Edge --
   -------------------------

   procedure Select_Trigger_Edge
     (Pin     : GPIO_Pin;
      Trigger : External_Triggers)
   is
      This_Pin : constant GPIO_Pin_Index := GPIO_Pin'Pos (Pin);
   begin
      Select_Trigger_Edge (This_Pin, Trigger);
   end Select_Trigger_Edge;

   -------------------------
   -- Select_Trigger_Edge --
   -------------------------

   procedure Select_Trigger_Edge
     (Pin     : GPIO_Pin_Index;
      Trigger : External_Triggers)
   is
   begin
      --  all those that are/include rising edge
      EXTI.RTSR (Pin) := Trigger in Interrupt_Rising_Edge  |
                           Interrupt_Rising_Falling_Edge |
                           Event_Rising_Edge  |
                           Event_Rising_Falling_Edge;

      -- all those that are/include falling edge
      EXTI.FTSR (Pin) := Trigger in Interrupt_Falling_Edge |
                             Interrupt_Rising_Falling_Edge |
                             Event_Falling_Edge |
                             Event_Rising_Falling_Edge;
   end Select_Trigger_Edge;

   -------------------------
   -- Select_Trigger_Edge --
   -------------------------

   procedure Select_Trigger_Edge
     (Pins    : GPIO_Pins;
      Trigger : External_Triggers)
   is
   begin
      for Pin of Pins loop
         Select_Trigger_Edge (Pin, Trigger);
      end loop;
   end Select_Trigger_Edge;

   ------------------------------
   -- Clear_External_Interrupt --
   ------------------------------

   procedure Clear_External_Interrupt (Pin : GPIO_Pin) is
   begin
      EXTI.PR (GPIO_Pin'Pos (Pin)) := 1;  -- yes, value is one to clear it
   end Clear_External_Interrupt;

   ------------------------------
   -- Clear_External_Interrupt --
   ------------------------------

   procedure Clear_External_Interrupt (Pin : GPIO_Pin_Index) is
   begin
      EXTI.PR (Pin) := 1; --  Set to 1 to clear
   end Clear_External_Interrupt;

end STM32.SYSCFG;
