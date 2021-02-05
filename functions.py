def df_trans(df):
  df = df.transpose().reset_index().rename(columns={'index':'name', 0:'prob'}).sort_values('prob', ascending = False).head(5)
  return df

from colors import color
from pyfiglet import figlet_format

class cat():
  """Títulos maiores em ASCII"""
  def __init__(self, texto, cor = "blue"):
    self.text = figlet_format(texto, font = "big")
    self.colour = color("█"*100,
                              cor,
                              style = "bold")
    self.cat = color(self.text, cor, style = "bold")
    
  def print(self):
    print('\n\n',self.cat)
