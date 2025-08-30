------------------------------------------------------------------------------
--                                                                          --
--                    Copyright (C) 2015-2025, AdaCore                      --
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
--     3. Neither the name of the copyright holder nor the names of its     --
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
------------------------------------------------------------------------------

with STM32.Device; use STM32.Device;

package body Serial_IO.Nonblocking is

   ----------
   -- Send --
   ----------

   procedure Send (This : in out Serial_Port;  Msg : not null access Message) is
   begin
      This.Start_Sending (Msg);
   end Send;

   -------------
   -- Receive --
   -------------

   procedure Receive (This : in out Serial_Port;  Msg : not null access Message) is
   begin
      This.Start_Receiving (Msg);
   end Receive;

   -----------------
   -- Serial_Port --
   -----------------

   protected body Serial_Port is

      -------------------------
      -- Handle_Transmission --
      -------------------------

      procedure Handle_Transmission is
      begin
         --  if Word_Lenth = 9 then
         --    -- handle the extra byte required for the 9th bit
         --  else  -- 8 data bits so no extra byte involved
         Device.Transmit (Character'Pos (Outgoing_Msg.Content_At (Next_Out)));
         Next_Out := Next_Out + 1;
         --  end if;
         if Next_Out > Outgoing_Msg.Length then
            Device.Disable_Interrupts (Source => Transmission_Complete);
            Outgoing_Msg.Signal_Transmission_Complete;
            Outgoing_Msg := null;
         end if;
      end Handle_Transmission;

      ----------------------
      -- Handle_Reception --
      ----------------------

      procedure Handle_Reception is
         Received_Char : constant Character := Character'Val (Device.Current_Input);
      begin
         if Received_Char /= Incoming_Msg.Terminator then
            Incoming_Msg.Append (Received_Char);
         end if;

         if Received_Char = Incoming_Msg.Terminator or else
            Incoming_Msg.Length = Incoming_Msg.Physical_Size
         then -- reception complete
            loop
               --  wait for device to clear the status
               exit when not Device.Status (Read_Data_Register_Not_Empty);
            end loop;
            Device.Disable_Interrupts (Source => Received_Data_Not_Empty);
            Incoming_Msg.Signal_Reception_Complete;
            Incoming_Msg := null;
         end if;
      end Handle_Reception;

      ---------
      -- ISR --
      ---------

      procedure ISR is
      begin
         --  check for data arrival
         if Device.Status (Read_Data_Register_Not_Empty) and then
           Device.Interrupt_Enabled (Received_Data_Not_Empty)
         then
            Detect_Errors (Is_Xmit_IRQ => False);
            Handle_Reception;
            Device.Clear_Status (Read_Data_Register_Not_Empty);
         end if;

         --  check for transmission ready
         if Device.Status (Transmission_Complete_Indicated) and then
           Device.Interrupt_Enabled (Transmission_Complete)
         then
            Detect_Errors (Is_Xmit_IRQ => True);
            Handle_Transmission;
            Device.Clear_Status (Transmission_Complete_Indicated);
         end if;
      end ISR;

      ----------
      -- Send --
      ----------

      procedure Start_Sending (Msg : not null access Message) is
      begin
         Outgoing_Msg := Msg;
         Next_Out := 1;

         Device.Enable_Interrupts (Parity_Error);
         Device.Enable_Interrupts (Error);
         Device.Enable_Interrupts (Transmission_Complete);
      end Start_Sending;

      -------------
      -- Receive --
      -------------

      procedure Start_Receiving (Msg : not null access Message) is
      begin
         Incoming_Msg := Msg;
         Incoming_Msg.Clear;

         Device.Enable_Interrupts (Parity_Error);
         Device.Enable_Interrupts (Error);
         Device.Enable_Interrupts (Received_Data_Not_Empty);
      end Start_Receiving;

      -------------------
      -- Detect_Errors --
      -------------------

      procedure Detect_Errors (Is_Xmit_IRQ : Boolean) is
      begin
         if Device.Status (Parity_Error_Indicated) and then
            Device.Interrupt_Enabled (Parity_Error)
         then
            Device.Clear_Status (Parity_Error_Indicated);
            if Is_Xmit_IRQ then
               Outgoing_Msg.Note_Error (Parity_Error_Detected);
            else
               Incoming_Msg.Note_Error (Parity_Error_Detected);
            end if;
         end if;

         if Device.Status (Framing_Error_Indicated) and then
            Device.Interrupt_Enabled (Error)
         then
            Device.Clear_Status (Framing_Error_Indicated);
            if Is_Xmit_IRQ then
               Outgoing_Msg.Note_Error (Frame_Error_Detected);
            else
               Incoming_Msg.Note_Error (Frame_Error_Detected);
            end if;
         end if;

         if Device.Status (USART_Noise_Error_Indicated) and then
            Device.Interrupt_Enabled (Error)
         then
            Device.Clear_Status (USART_Noise_Error_Indicated);
            if Is_Xmit_IRQ then
               Outgoing_Msg.Note_Error (Noise_Error_Detected);
            else
               Incoming_Msg.Note_Error (Noise_Error_Detected);
            end if;
         end if;

         if Device.Status (Overrun_Error_Indicated) and then
            Device.Interrupt_Enabled (Error)
         then
            Device.Clear_Status (Overrun_Error_Indicated);
            if Is_Xmit_IRQ then
               Outgoing_Msg.Note_Error (Overrun_Error_Detected);
            else
               Incoming_Msg.Note_Error (Overrun_Error_Detected);
            end if;
         end if;
      end Detect_Errors;

   end Serial_Port;

end Serial_IO.Nonblocking;
