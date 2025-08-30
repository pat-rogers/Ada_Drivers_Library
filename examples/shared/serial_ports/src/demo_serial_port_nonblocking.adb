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

--  A demonstration of a higher-level USART interface, using interrupts
--  to achieve non-blocking I/O (calls to Start_Sending and Receive return
--  potentially prior to I/O completion). The file declares the main procedure.

with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.

with Peripherals_Nonblocking;    use Peripherals_Nonblocking;
with Serial_IO.Nonblocking;      use Serial_IO.Nonblocking;
with Message_Buffers;            use Message_Buffers;

procedure Demo_Serial_Port_Nonblocking is

   Incoming : aliased Message (Physical_Size => 1024);  -- arbitrary size
   Outgoing : aliased Message (Physical_Size => 1024);  -- arbitrary size

   procedure Start_Sending (This : String);

   procedure Start_Sending (This : String) is
   begin
      Set (Outgoing, To => This);
      Send (COM, Outgoing'Unchecked_Access);
      Outgoing.Await_Transmission_Complete;
      --  We wait anyway, just to keep things simple for the display
   end Start_Sending;

begin
   Serial_IO.Initialize_Hardware (Peripheral);
   Serial_IO.Configure (COM.Device, Baud_Rate => 115_200);
   --  This baud rate selection is entirely arbitrary. Note that you may have
   --  to alter the settings of your host serial port to match this baud rate,
   --  or just change the above to match whatever the host serial port has set
   --  already. An application such as TerraTerm or RealTerm is helpful.

   Incoming.Set_Terminator (To => ASCII.CR);
   Start_Sending ("Enter text, terminated by CR.");
   --  Note that you may have to alter the settings on your host serial port so
   --  that the terminator char is not stripped off automatically by the host
   --  driver, which may happen especially when CR is the terminator. You may
   --  find that an application such as TerraTerm or RealTerm is helpful.

   loop
      Receive (COM, Incoming'Unchecked_Access);
      Incoming.Await_Reception_Complete;
      --  We wait anyway, just to keep things simple for the display
      Start_Sending ("Received : " & Incoming.Content);
   end loop;
end Demo_Serial_Port_Nonblocking;

