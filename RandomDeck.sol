pragma solidity ^0.4.19;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

//TODO Separate each contract out into their own file

contract RandomDeck is usingOraclize {
    address owner;
    
    bool hasSuit = false;
    uint suit = 0;
    
    uint maxSize = 52;
    CardStack deck;
    
    //Only allow owner to use function
    modifier onlyowner {
        if (msg.sender == owner) {
            _;
        }
    }
    
    function RandomDeck(uint max) public {
        maxSize = max;
        deck = new CardStack();
        owner = msg.sender;
        
        oraclize_setProof(proofType_Ledger); // sets the Ledger authenticity proof in the constructor
        newNumber(0); //Doesn't matter what we put here, just need to start generation
    }
    
    // the callback function is called by Oraclize when the result is ready
    // the oraclize_randomDS_proofVerify modifier prevents an invalid proof to execute this function code:
    // the proof validity is fully verified on-chain
    function __callback(bytes32 _queryId, string _result, bytes _proof) { 
        // if we reach this point successfully, it means that the attached authenticity proof has passed!
        if (msg.sender != oraclize_cbAddress()) throw;
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) == 0) {
            // the proof verification has passed
            // now that we know that the random number was safely generated, let's use it..
            
            if (hasSuit) {
                uint maxRange = 52; // this is the highest uint we want to get.
                uint randomNumber = uint(sha3(_result)) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange] range
                newNumber(randomNumber); //We have our random number and suit! Let's make the card.
            } else {
                suit = uint(sha3(_result)) % 4;
                hasSuit = true;
                requestRandom(); //Now that we have a suit, let's get another random number
            }
        }
    }
    
    function requestRandom() payable onlyowner {
        uint N = 7; // number of random bytes we want the datasource to return
        uint delay = 0; // number of seconds to wait before the execution takes place
        uint callbackGas = 200000; // amount of gas we want Oraclize to set for the callback function
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // this function internally generates the correct oraclize_query and returns its queryId
    }
    
    function newNumber(uint number) payable onlyowner {
        if (!hasSuit) {
            requestRandom(); //We don't have a suit yet, lets generate one
        } else {
            Card c = new Card(number, suit);
            deck.add(c);
            hasSuit = false;
        }
        
        if (deck.getSize() < maxSize) {
            requestRandom(); //If we still need more cards, let's generate a random suit!
        }
    }
    
    
    function peek() public constant onlyowner returns (Card) {
        return deck.peek();
    } 
    
    function pop() public onlyowner returns (Card) {
        return deck.pop();
    }
    
    function getSize() public constant returns (uint256) {
        return deck.getSize();
    }
}

contract CardStack {
    CardNode head;
    uint256 size;
    address owner;
    
    modifier onlyowner {
        if (msg.sender == owner) {
            _;
        }
    }
    
    function CardStack() public {
        owner = msg.sender;
    }
    
    function add(Card number) public onlyowner {
        if (size > 1) {
            CardNode newNode = new CardNode(number);
            newNode.setNextNode(head);
            head = newNode;
        } else {
            head = new CardNode(number);
        }
        size++;
    }
    
    function pop() public onlyowner returns (Card) {
        CardNode newHead = head.getNextNode();
        head = newHead;
        size--;
        return newHead.getData();
    }
    
    function peek() public constant onlyowner returns (Card) {
        return head.getData();
    }
    
    function getSize() public constant onlyowner returns (uint256) {
        return size;
    }
    
    function clear() public onlyowner {
        size = 0;
        head.clear(); //Clear everything in the head
    }
}

contract CardNode {
    bool hasNext;
    CardNode next;
    Card data;
    
    function CardNode(Card num) public {
        data = num;
    }
    
    function getData() public constant returns (Card) {
        return data;
    }
    
    function getNextNode() public constant returns (CardNode) {
        return next;
    }
    
    function hasNextNode() public constant returns (bool) {
        return hasNext;
    }
    
    function setNextNode(CardNode node) public {
        hasNext = true;
        next = node;
    }
    
    function clear() public {
        hasNext = false;
        next.clear();
    }
}

contract Card {
    uint public number;
    uint public suit;
    
    function Card(uint num, uint s) public {
        number = num;
        suit = s;
    }
}
