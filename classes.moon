
class PIN
  PINID: 0
  newPINID: => @PINID += 1

class INPUTPIN extends PIN

class OUTPUT extends PIN


class BOARDOBJECT

class GATE extends BOARDOBJECT

class AND extends GATE

class OR extends GATE

class NAND extends GATE

class NOR extends GATE

class XOR extends GATE

class XNOR extends GATE

class NOT extends GATE



class PERIPHERAL extends BOARDOBJECT

class INPUT extends PERIPHERAL

class OUTPUT extends PERIPHERAL

class BUFFER extends PERIPHERAL

class CLOCK extends PERIPHERAL