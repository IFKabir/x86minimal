/**
 * @file kmain.cpp
 * @brief Main kernel entry point for ZeroRing.
 *
 * This file contains the C++ kernel functions that are called from the
 * assembly loader (`loader.s`). It serves as the primary location for
 * all future kernel-level C++ code.
 *
 * @see loader.s for the Multiboot entry point and stack setup.
 * @see link.ld for the memory layout and section placement.
 */

/**
 * @brief Computes the sum of three integers.
 *
 * A simple test function called from the assembly loader to verify that
 * the C calling convention and stack setup are working correctly.
 * The result is stored in EAX as per the cdecl convention.
 *
 * @param arg1 First integer operand.
 * @param arg2 Second integer operand.
 * @param arg3 Third integer operand.
 * @return The sum `arg1 + arg2 + arg3`.
 *
 * @note This function uses C linkage (`extern "C"`) so it can be called
 *       directly from NASM assembly without name mangling.
 */
extern "C" int sum_of_three(int arg1, int arg2, int arg3)
{
    return arg1 + arg2 + arg3;
}

/**
 * @brief Main kernel entry point.
 *
 * Called by the assembly loader after initial hardware setup.
 * This is where all future C++ OS code will be written — interrupt
 * handlers, memory management, device drivers, etc.
 *
 * Currently a no-op; control returns to the loader's infinite loop.
 *
 * @note Uses C linkage (`extern "C"`) for assembly interop.
 */
extern "C" void kmain()
{
    // Future OS code goes here.
}