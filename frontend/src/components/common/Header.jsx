import React from 'react';
import { BookOpen, Settings, HelpCircle } from 'lucide-react';

const Header = () => {
  return (
    <header className="bg-white shadow-sm border-b border-gray-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo and Title */}
          <div className="flex items-center">
            <div className="flex-shrink-0 flex items-center">
              <BookOpen className="h-8 w-8 text-blue-600" />
              <div className="ml-3">
                <h1 className="text-xl font-semibold text-gray-900">
                  EduAgent
                </h1>
                <p className="text-sm text-gray-500">
                  Physics & Mathematics AI Assistant
                </p>
              </div>
            </div>
          </div>

          {/* Navigation */}
          <nav className="hidden md:flex space-x-8">
            <button
              className="text-gray-500 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
            >
              Chat
            </button>
            <button
              className="text-gray-500 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
            >
              Knowledge Base
            </button>
            <button
              className="text-gray-500 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
            >
              Examples
            </button>
          </nav>

          {/* Actions */}
          <div className="flex items-center space-x-4">
            <button
              type="button"
              className="text-gray-400 hover:text-gray-500 p-2 rounded-md"
              title="Help"
            >
              <HelpCircle className="h-5 w-5" />
            </button>
            <button
              type="button"
              className="text-gray-400 hover:text-gray-500 p-2 rounded-md"
              title="Settings"
            >
              <Settings className="h-5 w-5" />
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header; 