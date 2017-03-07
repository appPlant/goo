# Write tests where the program should fail
module FailingUseCaseTests
  def test_copy_failed
    command = '-c="touch test && cp test ./test/test"'
    output, error, status = Open3.capture3(PATH, BIN, command,
                                          '-d=true', 'app')
    check_no_error(output, error, 'copy_failed')
    assert_true status.success?, 'Process did exit cleanly'
    assert_include output, 'Process exited with status 1', 'wrong error'
  end
end
