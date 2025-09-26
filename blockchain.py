import hashlib
import json
from time import time

class Blockchain (object):
    def __init__(self):
        self.chain = [];
        self.current_transactions = [];
        
        #creating new genesis (first) block
    
        self.new_block(previous_hash=1, proof=100);
    
    def new_block(self, proof, previous_hash=None): #will create a new Block and add to chain
        
        block = {
            'index': len(self.chain) + 1,
            'timestamp': time(),
            'transactions': self.current_transactions,
            'proof': proof,
            'previous_hash': previous_hash or self.hash(self.chain[-1]),
            
        }
        
        self.current_transactions = []
        
        self.chain.append(block);
        
        return block;
    
    def new_transaction(self, sender, recipient, amount): #specifies a new transaction
        
        self.current_transactions.append({
            'sender': sender,
            'recipient': recipient,
            'amount': amount,
        })
                
        return self.last_block['index'] + 1;
    
    @staticmethod
    def hash(block):
        pass
    
    @property
    def last_block(self):
        pass