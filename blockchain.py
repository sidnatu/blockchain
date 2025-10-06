import hashlib
import json
from time import time
from uuid import uuid4
from textwrap import dedent
from flask import Flask, jsonify, request

class Blockchain (object):
    def __init__(self):
        self.chain = [];
        self.current_transactions = [];
        
        #creating new genesis (first) block
    
        self.new_block(previous_hash=1, proof=100); #every time blockchain is called, it creates a genesis
    
    def new_block(self, proof, previous_hash=None): #will create a new Block and add to chain
        #could add error that enforces minimum one transaction per block
        block = {
            'index': len(self.chain) + 1,
            'timestamp': time(),
            'transactions': self.current_transactions,
            'proof': proof,
            'previous_hash': previous_hash or self.hash(self.chain[-1]),
            
        }
        
        self.current_transactions = [] #has to wipe all pending transactions
        
        self.chain.append(block); #adds itself to the blockchain
        
        return block;
    
    def new_transaction(self, sender, recipient, amount): #specifies a new transaction
        
        self.current_transactions.append({
            'sender': sender,
            'recipient': recipient,
            'amount': amount,
        })
                
        return self.last_block['index'] + 1;
    
    def proof_of_work(self,last_proof, zeros=4):
        #find p such that hash(p * p_past) contains 4 leading zeros, p is current proof
        
        proof = 0;
        
        while self.valid_proof(last_proof, proof) is False:
            proof += 1;
            
        return proof
    
    @staticmethod
    def valid_proof(last_proof, proof, zeros=4):
        #validates the proof does hash(p * p_past) have 4 leading zeros
        
        guess = f'{last_proof}{proof}'.encode()
        hashed_guess = hashlib.sha256(guess).hexdigest();
        return hashed_guess.startswith('0' * zeros)
    
    @staticmethod
    def hash(block):
        
        block_string = json.dumps(block, sort_keys=True).encode() #converts the block info to a JSON string, and then bytes
        return hashlib.sha256(block_string).hexdigest() #hashes using sha256 and formats it in hexadecimal
        
    
    @property
    def last_block(self):
        return self.chain[-1];
    
## CREATING QUICK FLASK TESTER
    
app = Flask(__name__) # instantiates node
    
node_id = str(uuid4()).replace("-"," ") # get a node uid
    
blkchain = Blockchain()

@app.route('/mine', methods=['GET'])
def mine():
    #run PoW alg to get next proof
    last_block = blkchain.last_block;
    last_proof = last_block['proof'];
    proof = blkchain.proof_of_work(last_proof)
    
    #reward for finding proof, sender is 0 to indicate a new coin
    blkchain.new_transaction(
        sender="0",
        recipient=node_id,
        amount=1,        
    )
    
    #forging new block to add to the chain
    previous_hash = blkchain.hash(last_block)
    block = blkchain.new_block(proof, previous_hash)
    
    response = {
        'message': 'New Block Forged',
        'index': block['index'],
        'transactions': block['transactions'],
        'proof': block['proof'],
        'previous_hash':  block['previous_hash'],
    }
    return jsonify(response), 200

@app.route('/transactions/new', methods=['POST'])
def new_txn():
    values = request.get_json()
    
    #checking to see if all valid info is added
    required = ['sender', 'recipient', 'amount']
    if not all(k in values for k in required):
        return 'Missing values', 400;
    
    #creating a new transaction
    index = blkchain.new_transaction(values['sender'], values['recipient'], values['amount']);
    response = {'Message': f'Transaction will be added to Block {index}'}
    return jsonify(response), 201;


@app.route('/chain', methods=['GET'])
def full_chain():
    response = {
        'chain': blkchain.chain,
        'length': len(blkchain.chain),
    }
    return jsonify(response), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)