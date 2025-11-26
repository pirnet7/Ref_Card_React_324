import { render, screen } from '@testing-library/react';
import App from './App';

import React from 'react';

test('renders app header', () => {
  render(<App />);
  const heading = screen.getByText(/App Ref. Card 02/i);
  expect(heading).toBeInTheDocument();
});
