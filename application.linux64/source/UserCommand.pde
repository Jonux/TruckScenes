
enum UserCommand {
  UNKNOWN('.'), START('s'), END('e'), APPROVE('+'), DENY('-'), RESTART('r'), NEXT('p');
  
  private final char value;
    private UserCommand(char value){
        this.value = value;
    }
    
    public static UserCommand fromSerial(char c) {
        switch (c) {
          case 's': return START;
          case 'd': return END;
          case '-': return DENY;
          case '+': return APPROVE;
          case 'p': return NEXT;
          case 'n': return RESTART;
          default: return UNKNOWN;
        }
    }
    
    public static UserCommand fromKeyboard(char c) {
        switch (c) {
          case 's': return START;
          case 'e': return END;
          case 'r': return RESTART;
          case 'n': return DENY;
          case 'y': return APPROVE;
          case 'p': return NEXT;
          default: return UNKNOWN;
        }
    }

  public char getValue() {
    return value;
  }
}