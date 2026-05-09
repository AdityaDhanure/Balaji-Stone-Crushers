import { departmentService, employeeService, documentService, leaveService } from './service.js';

export const departmentController = {
  // Get all departments
  async getAll(req, res) {
    try {
      const departments = await departmentService.getAllDepartments();
      res.json({ success: true, data: departments });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  },

  // Create department
  async create(req, res) {
    try {
      const department = await departmentService.createDepartment(req.body);
      res.status(201).json({ success: true, data: department });
    } catch (error) {
      res.status(400).json({ success: false, error: error.message });
    }
  },

  // Update department
  async update(req, res) {
    try {
      const department = await departmentService.updateDepartment(req.params.id, req.body);
      res.json({ success: true, data: department });
    } catch (error) {
      res.status(400).json({ success: false, error: error.message });
    }
  },

  // Delete department
  async delete(req, res) {
    try {
      await departmentService.deleteDepartment(req.params.id);
      res.json({ success: true, message: 'Department deleted successfully' });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
};

export const employeeController = {
  // Get all employees with filters from query params
  async getAll(req, res) {
    try {
      const filters = {};
      if (req.query.isActive !== undefined) {
        filters.isActive = req.query.isActive === 'true';
      }
      if (req.query.departmentId) {
        filters.departmentId = parseInt(req.query.departmentId);
      }
      if (req.query.employeeType) {
        filters.employeeType = req.query.employeeType;
      }
      const employees = await employeeService.getAllEmployees(filters);
      res.json(employees);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get single employee by ID
  async getById(req, res) {
    try {
      const employee = await employeeService.getEmployeeById(req.params.id);
      if (!employee) {
        return res.status(404).json({ error: 'Employee not found' });
      }
      res.json(employee);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get only active employees
  async getActive(req, res) {
    try {
      const employees = await employeeService.getActiveEmployees();
      res.json(employees);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Create new employee
  async create(req, res) {
    try {
      const employee = await employeeService.createEmployee(req.body);
      res.status(201).json(employee);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Update employee
  async update(req, res) {
    try {
      const employee = await employeeService.updateEmployee(req.params.id, req.body);
      res.json(employee);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Delete employee
  async delete(req, res) {
    try {
      await employeeService.deleteEmployee(req.params.id);
      res.json({ message: 'Employee deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get next employee code
  async getNextCode(req, res) {
    try {
      const code = await employeeService.getNextCode();
      res.json({ employee_code: code });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get employee statistics
  async getStats(req, res) {
    try {
      const stats = await employeeService.getEmployeeStats();
      res.json(stats);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};

export const documentController = {
  // Get documents for employee
  async getByEmployee(req, res) {
    try {
      const documents = await documentService.getDocumentsByEmployee(req.params.employeeId);
      res.json(documents);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Create employee document
  async create(req, res) {
    try {
      const document = await documentService.createDocument({
        ...req.body,
        employee_id: req.params.employeeId
      });
      res.status(201).json(document);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Delete document
  async delete(req, res) {
    try {
      await documentService.deleteDocument(req.params.id);
      res.json({ message: 'Document deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};

export const leaveController = {
  // Get leaves for employee
  async getByEmployee(req, res) {
    try {
      const leaves = await leaveService.getLeavesByEmployee(req.params.employeeId);
      res.json(leaves);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get pending leave requests
  async getPending(req, res) {
    try {
      const leaves = await leaveService.getPendingLeaves();
      res.json(leaves);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Create leave request
  async create(req, res) {
    try {
      const leave = await leaveService.createLeave(req.body);
      res.status(201).json(leave);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Approve/reject leave
  async updateStatus(req, res) {
    try {
      const data = { ...req.body, approved_by: req.user?.id };
      const leave = await leaveService.updateLeaveStatus(req.params.id, data.status, data.approved_by);
      res.json(leave);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Delete leave request
  async delete(req, res) {
    try {
      await leaveService.deleteLeave(req.params.id);
      res.json({ message: 'Leave deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};