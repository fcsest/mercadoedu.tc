from colors import color
from pyfiglet import figlet_format

class cat():
  """Títulos maiores em ASCII"""
  def __init__(self, texto, cor = "blue", bg = None):
    self.text = figlet_format(texto, font = "big")
    self.colour = cor
    self.cat = color(self.text, cor, bg, style = "bold")
    
  def print(self):
    if(self.colour == 'green'):
      print('\n\n')
    elif(self.colour == 'blue'):
      print('\n')
    print(self.cat)

def ask_user(question):
    while "the answer is invalid":
        reply = str(input(question+' (s/n): ')).lower().strip()
        if reply[:1] == 's':
            return True
        if reply[:1] == 'n':
            return False

def df_trans(df):
  df = df.transpose().reset_index().rename(columns={'index':'name', 0:'prob'}).sort_values('prob', ascending = False).head(5)
  return df
