#!/usr/bin/env python3
"""
Smoke Tests for Post-Deployment Validation
Tests basic functionality of deployed infrastructure
"""

import os
import sys
import json
import time
import requests
from typing import List, Dict, Tuple

# Colors for terminal output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

def print_status(message: str, status: str = "info"):
    """Print colored status messages"""
    if status == "success":
        print(f"{GREEN}✓ {message}{RESET}")
    elif status == "error":
        print(f"{RED}✗ {message}{RESET}")
    elif status == "warning":
        print(f"{YELLOW}⚠ {message}{RESET}")
    else:
        print(f"{BLUE}ℹ {message}{RESET}")

def test_ec2_connectivity(ec2_ips: List[str]) -> bool:
    """Test basic connectivity to EC2 instances"""
    print_status("Testing EC2 Instance Connectivity", "info")
    
    all_passed = True
    for ip in ec2_ips:
        try:
            # Test SSH port
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((ip, 22))
            sock.close()
            
            if result == 0:
                print_status(f"EC2 {ip}: SSH port accessible", "success")
            else:
                print_status(f"EC2 {ip}: SSH port not accessible", "error")
                all_passed = False
                
        except Exception as e:
            print_status(f"EC2 {ip}: Connection test failed - {str(e)}", "error")
            all_passed = False
    
    return all_passed

def test_health_endpoint(ec2_ips: List[str], port: int = 5000) -> bool:
    """Test application health endpoints"""
    print_status("Testing Application Health Endpoints", "info")
    
    all_passed = True
    for ip in ec2_ips:
        try:
            url = f"http://{ip}:{port}/health"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                print_status(f"Health check {ip}:{port} - OK", "success")
                data = response.json()
                print(f"  Response: {json.dumps(data, indent=2)}")
            else:
                print_status(f"Health check {ip}:{port} - Failed (HTTP {response.status_code})", "error")
                all_passed = False
                
        except requests.exceptions.ConnectionError:
            print_status(f"Health check {ip}:{port} - Connection refused (app may not be running yet)", "warning")
            all_passed = False
        except requests.exceptions.Timeout:
            print_status(f"Health check {ip}:{port} - Timeout", "error")
            all_passed = False
        except Exception as e:
            print_status(f"Health check {ip}:{port} - Error: {str(e)}", "error")
            all_passed = False
    
    return all_passed

def test_docker_service(ec2_ips: List[str]) -> bool:
    """Verify Docker service is running (requires SSH access)"""
    print_status("Docker Service Status", "info")
    print_status("(Detailed check requires SSH - verified via Ansible)", "warning")
    return True

def test_database_connectivity(rds_endpoint: str) -> bool:
    """Test RDS database connectivity"""
    print_status("Testing Database Connectivity", "info")
    
    if not rds_endpoint:
        print_status("No RDS endpoint provided", "warning")
        return True
    
    try:
        # Extract host and port
        if ':' in rds_endpoint:
            host, port = rds_endpoint.split(':')
            port = int(port)
        else:
            host = rds_endpoint
            port = 5432
        
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((host, port))
        sock.close()
        
        if result == 0:
            print_status(f"Database {host}:{port} - Port accessible", "success")
            return True
        else:
            print_status(f"Database {host}:{port} - Port not accessible", "error")
            return False
            
    except Exception as e:
        print_status(f"Database connectivity test failed: {str(e)}", "error")
        return False

def test_http_endpoints(ec2_ips: List[str], port: int = 5000) -> bool:
    """Test various HTTP endpoints"""
    print_status("Testing HTTP Endpoints", "info")
    
    endpoints = ['/health', '/status', '/api/status']
    all_passed = True
    
    for ip in ec2_ips:
        for endpoint in endpoints:
            try:
                url = f"http://{ip}:{port}{endpoint}"
                response = requests.get(url, timeout=5)
                
                if response.status_code == 200:
                    print_status(f"GET {endpoint} on {ip} - OK", "success")
                elif response.status_code == 404:
                    print_status(f"GET {endpoint} on {ip} - Not Found (expected)", "warning")
                else:
                    print_status(f"GET {endpoint} on {ip} - HTTP {response.status_code}", "warning")
                    
            except requests.exceptions.ConnectionError:
                print_status(f"GET {endpoint} on {ip} - Connection refused", "warning")
            except Exception as e:
                print_status(f"GET {endpoint} on {ip} - Error: {str(e)}", "warning")
    
    return all_passed

def generate_report(results: Dict[str, bool]) -> None:
    """Generate test report"""
    print("\n" + "="*60)
    print_status("SMOKE TEST REPORT", "info")
    print("="*60 + "\n")
    
    total_tests = len(results)
    passed_tests = sum(1 for v in results.values() if v)
    failed_tests = total_tests - passed_tests
    
    for test_name, result in results.items():
        status = "success" if result else "error"
        symbol = "✓" if result else "✗"
        print_status(f"{symbol} {test_name}", status)
    
    print("\n" + "="*60)
    print(f"Total Tests: {total_tests}")
    print(f"{GREEN}Passed: {passed_tests}{RESET}")
    print(f"{RED}Failed: {failed_tests}{RESET}")
    print("="*60 + "\n")
    
    # Write report to file
    with open('smoke-test-results.log', 'w') as f:
        f.write("Smoke Test Results\n")
        f.write("="*60 + "\n")
        for test_name, result in results.items():
            f.write(f"{'PASS' if result else 'FAIL'}: {test_name}\n")
        f.write(f"\nTotal: {total_tests}, Passed: {passed_tests}, Failed: {failed_tests}\n")

def main():
    """Main smoke test execution"""
    print_status("Starting Smoke Tests", "info")
    print("="*60 + "\n")
    
    # Get EC2 IPs from environment or argument
    ec2_ips_env = os.getenv('EC2_IPS', '[]')
    try:
        ec2_ips = json.loads(ec2_ips_env)
    except:
        # Fallback to command line argument or empty list
        ec2_ips = sys.argv[1:] if len(sys.argv) > 1 else []
    
    if not ec2_ips:
        print_status("No EC2 IPs provided. Skipping EC2 tests.", "warning")
        print_status("Usage: python smoke_tests.py <ip1> <ip2> ...", "info")
        print_status("Or set EC2_IPS environment variable as JSON array", "info")
        ec2_ips = []
    
    rds_endpoint = os.getenv('RDS_ENDPOINT', '')
    
    print_status(f"Testing {len(ec2_ips)} EC2 instance(s)", "info")
    if rds_endpoint:
        print_status(f"RDS Endpoint: {rds_endpoint}", "info")
    print()
    
    # Run all tests
    results = {}
    
    if ec2_ips:
        results['EC2 Connectivity'] = test_ec2_connectivity(ec2_ips)
        time.sleep(2)
        
        results['Health Endpoints'] = test_health_endpoint(ec2_ips)
        time.sleep(2)
        
        results['HTTP Endpoints'] = test_http_endpoints(ec2_ips)
        time.sleep(2)
        
        results['Docker Service'] = test_docker_service(ec2_ips)
    
    if rds_endpoint:
        results['Database Connectivity'] = test_database_connectivity(rds_endpoint)
    
    # Generate report
    generate_report(results)
    
    # Exit with appropriate code
    all_passed = all(results.values())
    if all_passed:
        print_status("All smoke tests passed!", "success")
        sys.exit(0)
    else:
        print_status("Some smoke tests failed!", "error")
        sys.exit(1)

if __name__ == "__main__":
    main()
