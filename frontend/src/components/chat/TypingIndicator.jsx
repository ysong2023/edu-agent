import React from 'react';
import { Bot } from 'lucide-react';

const TypingIndicator = () => {
  return (
    <div className="flex justify-start mb-4">
      <div className="flex max-w-3xl">
        {/* Avatar */}
        <div className="flex-shrink-0 mr-3">
          <div className="w-8 h-8 rounded-full bg-green-500 text-white flex items-center justify-center">
            <Bot className="h-4 w-4" />
          </div>
        </div>
        
        {/* Typing Animation */}
        <div className="flex-1">
          <div className="inline-block p-3 bg-white border border-gray-200 rounded-lg">
            <div className="flex items-center space-x-1">
              <span className="text-sm text-gray-500">AI is thinking</span>
              <div className="flex space-x-1">
                <div className="w-1 h-1 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
                <div className="w-1 h-1 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
                <div className="w-1 h-1 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TypingIndicator; 