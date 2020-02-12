with Ada.Text_IO; use Ada.Text_IO;

procedure Leader_Election is

   type Node_ID is range 1 .. 20;

   type Msg_T is record
     L_Chosen   : Boolean;
     challenge   : Node_ID;
   end record;

   protected type Channel is
     entry Send (o_msg:  in Msg_T);
     entry Recv (i_msg: out Msg_T);
   private 
     Msg     : Msg_T;
     Ready   : Boolean := True;
   end Channel;

   protected body Channel is

     entry Send (o_msg:  in Msg_T) 
     when Ready is
     begin
       Msg := o_msg;
       Ready := False;
     end;

     entry Recv (i_msg: out Msg_T) 
     when not Ready is
     begin
       i_msg := Msg;
       Ready := True;
     end;
   end Channel;

   type Ch_Access is access all Channel;

   Ch_Arr : array (Node_ID) of Ch_Access 
                  := (others => new Channel);

   task type node (         ID: Node_ID; 
                   Out_Channel: Ch_Access; 
                    In_Channel: Ch_Access );

   type Node_Access is access node;

   task body node is
     Current                : Node_ID := ID;
     Trial                  : Msg_T;
     L_Chosen, Elected : Boolean := False;
   begin

     Out_Channel.Send((Elected, Current));
     --Put_Line (Node_ID'Image (ID) & ": Sent: " & Node_ID'Image (Current) & Boolean'Image(Elected) );
     while not L_Chosen loop
       --delay 0.2;       
 
       In_Channel.Recv(Trial);

       Put_Line (Node_ID'Image (ID) & ": Recv: " & Node_ID'Image (Trial.Challenge) & Boolean'Image(Trial.L_Chosen) );
        
       if Trial.L_Chosen then L_Chosen := True; 
       end if;
        
       if not Elected then
 
         if Trial.Challenge = ID then 
           --Put_Line("ELECT:" & Node_ID'Image(ID));
           Elected := True;

         elsif Trial.Challenge > Current then 
           Current := Trial.Challenge;
         end if;

         Out_Channel.Send((L_Chosen or Elected, Current));
         Put_Line (Node_ID'Image (ID) & ": Sent: " & Node_ID'Image (Current) & Boolean'Image(L_Chosen or Elected) );
       end if;

     end loop;

     if Elected then Put_Line(Node_ID'Image(ID) & " Elected Leader!"); 
     end if;
   end node;

   New_Node : Node_Access;
   Prev : Node_ID := Node_ID'last;

begin
   for I in Node_ID'Range loop
      New_Node := new Node (I, Ch_Arr(I), Ch_Arr(Prev));
      Prev := I;
   end loop;
end Leader_Election;
