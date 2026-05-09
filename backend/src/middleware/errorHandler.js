// Global error handler - catches unhandled errors
const errorHandler = (err, req, res, next) => {
  console.error('Error:', err.message);

  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';

  // Handle PostgreSQL duplicate key error
  if (err.code === '23505') {
    statusCode = 400;
    message = 'Duplicate entry — record already exists';
  }

  // Handle PostgreSQL foreign key violation error
  if (err.code === '23503') {
    statusCode = 400;
    message = 'Referenced record does not exist';
  }

  res.status(statusCode).json({
    success: false,
    message,
    // Show stack trace only in development
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

export default errorHandler;