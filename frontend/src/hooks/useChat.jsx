import { useReducer, useCallback } from 'react';
import { toast } from 'react-hot-toast';

// Initial state
const initialState = {
  messages: [],
  isLoading: false,
  error: null,
  history: []
};

// Action types
const ACTIONS = {
  SEND_MESSAGE_START: 'SEND_MESSAGE_START',
  SEND_MESSAGE_SUCCESS: 'SEND_MESSAGE_SUCCESS',
  SEND_MESSAGE_ERROR: 'SEND_MESSAGE_ERROR',
  ADD_USER_MESSAGE: 'ADD_USER_MESSAGE',
  CLEAR_ERROR: 'CLEAR_ERROR',
  CLEAR_MESSAGES: 'CLEAR_MESSAGES'
};

function chatReducer(state, action) {
  switch (action.type) {
    case ACTIONS.SEND_MESSAGE_START:
      return {
        ...state,
        isLoading: true,
        error: null
      };
    
    case ACTIONS.ADD_USER_MESSAGE:
      return {
        ...state,
        messages: [...state.messages, action.payload],
        history: [...state.history, { role: 'user', content: action.payload.content }]
      };
    
    case ACTIONS.SEND_MESSAGE_SUCCESS:
      return {
        ...state,
        isLoading: false,
        messages: [...state.messages, action.payload.message],
        history: [...state.history, { role: 'assistant', content: action.payload.message.content }],
        error: null
      };
    
    case ACTIONS.SEND_MESSAGE_ERROR:
      return {
        ...state,
        isLoading: false,
        error: action.payload
      };
    
    case ACTIONS.CLEAR_ERROR:
      return {
        ...state,
        error: null
      };
    
    case ACTIONS.CLEAR_MESSAGES:
      return {
        ...initialState
      };
    
    default:
      return state;
  }
}

// Main hook
export function useChat() {
  const [state, dispatch] = useReducer(chatReducer, initialState);

  // Send message
  const sendMessage = useCallback(async (content) => {
    if (!content.trim()) {
      toast.error('Please enter message content');
      return;
    }

    // Add user message
    const userMessage = {
      id: Date.now(),
      type: 'user',
      content: content.trim(),
      timestamp: new Date().toISOString()
    };

    dispatch({
      type: ACTIONS.ADD_USER_MESSAGE,
      payload: userMessage
    });

    dispatch({ type: ACTIONS.SEND_MESSAGE_START });

    try {
      // Build request data
      const requestData = {
        message: content.trim(),
        history: state.history
      };

      console.log('Sending request:', requestData);

      // Send API request
      const response = await fetch('http://localhost:8000/api/v1/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestData),
        timeout: 30000, // 30 second timeout
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      // Handle response
      const data = await response.json();
      console.log('Received response:', data);

      const assistantMessage = {
        id: Date.now() + 1,
        type: 'assistant',
        content: data.message || 'No response received',
        timestamp: new Date().toISOString(),
        tool_results: data.tool_results || []
      };

      // If there are tool execution results, show success notification
      if (data.tool_results && data.tool_results.length > 0) {
        const toolNames = data.tool_results.map(result => result.tool_name).join(', ');
        toast.success(`Tools executed: ${toolNames}`);
      }

      dispatch({
        type: ACTIONS.SEND_MESSAGE_SUCCESS,
        payload: { message: assistantMessage }
      });

    } catch (error) {
      console.error('Failed to send message:', error);
      
      let errorMessage = 'Failed to send message, please try again';
      
      if (error.name === 'TypeError') {
        // Server response error
        errorMessage = 'Server error, please check if the backend service is running';
      } else if (error.message.includes('Failed to fetch')) {
        // Network error
        errorMessage = 'Network connection failed, please check if the backend service is running';
      }

      toast.error(errorMessage);
      
      dispatch({
        type: ACTIONS.SEND_MESSAGE_ERROR,
        payload: errorMessage
      });
    }
  }, [state.history]);

  const clearMessages = useCallback(() => {
    dispatch({ type: ACTIONS.CLEAR_MESSAGES });
  }, []);

  const clearError = useCallback(() => {
    dispatch({ type: ACTIONS.CLEAR_ERROR });
  }, []);

  return {
    messages: state.messages,
    isLoading: state.isLoading,
    error: state.error,
    sendMessage,
    clearMessages,
    clearError
  };
} 