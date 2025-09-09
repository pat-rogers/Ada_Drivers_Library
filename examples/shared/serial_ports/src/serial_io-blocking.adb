------------------------------------------------------------------------------
--                                                                          --
--                  Copyright (C) 2015-2025, AdaCore                        --
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

with HAL;

package body Serial_IO.Blocking is

   ----------
   -- Send --
   ----------

   procedure Send (This : in out Serial_Port;  Msg : not null access Message) is
   begin
      for Next in 1 .. Msg.Length loop
         Await_Send_Ready (This.Device);
         This.Device.Transmit
           (Character'Pos (Msg.Content_At (Next)));
      end loop;
   end Send;

   -------------
   -- Receive --
   -------------

   procedure Receive (This : in out Serial_Port;  Msg : not null access Message) is
      Received_Char : Character;
      Raw           : HAL.UInt9;
   begin
      Msg.Clear;
      Receiving : for K in 1 .. Msg.Physical_Size loop
         Await_Data_Available (This.Device);
         This.Device.Receive (Raw);
         Received_Char := Character'Val (Raw);
         exit Receiving when Received_Char = Msg.Terminator;
         Msg.Append (Received_Char);
      end loop Receiving;
   end Receive;

   ----------------------
   -- Await_Send_Ready --
   ----------------------

   procedure Await_Send_Ready (This : access USART) is
   begin
      loop
         exit when This.Tx_Ready;
      end loop;
   end Await_Send_Ready;

   --------------------------
   -- Await_Data_Available --
   --------------------------

   procedure Await_Data_Available (This : access USART) is
   begin
      loop
         exit when This.Rx_Ready;
      end loop;
   end Await_Data_Available;

end Serial_IO.Blocking;
