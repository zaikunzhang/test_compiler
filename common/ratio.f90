module ratio_mod
!--------------------------------------------------------------------------------------------------!
! This module calculates the reduction ratio for trust-region methods.
!
! Coded by Zaikun ZHANG (www.zhangzk.net).
!
! Started: September 2021
!
! Last Modified: Sunday, December 11, 2022 AM01:29:35
!--------------------------------------------------------------------------------------------------!

implicit none
private
public :: redrat


contains


function redrat(ared, pred, rshrink) result(ratio)
!--------------------------------------------------------------------------------------------------!
! This function evaluates the reduction ratio of a trust-region step, handling Inf/NaN properly.
!--------------------------------------------------------------------------------------------------!
use, non_intrinsic :: consts_mod, only : RP, ONE, HALF, REALMAX, DEBUGGING
use, non_intrinsic :: infnan_mod, only : is_nan, is_posinf, is_neginf
use, non_intrinsic :: debug_mod, only : assert
implicit none

! Inputs
real(RP), intent(in) :: ared
real(RP), intent(in) :: pred
real(RP), intent(in) :: rshrink  ! When RATIO <= RSHRINK, DELTA will be shrunk.

! Outputs
real(RP) :: ratio

! Local variables
character(len=*), parameter :: srname = 'REDRAT'

! Preconditions
if (DEBUGGING) then
    call assert(rshrink >= 0, 'RSHRINK >= 0', srname)
end if

!====================!
! Calculation starts !
!====================!

if (is_nan(ared)) then
    ! This should not happen in unconstrained problems due to the moderated extreme barrier.
    ratio = -REALMAX
elseif (is_nan(pred) .or. pred <= 0) then
    ! The trust-region subproblem solver fails in this rare case. Instead of terminating as Powell's
    ! original code does, we set RATIO as follows so that the solver may continue to progress.
    if (ared > 0) then
        ! The trial point will be accepted, but the trust-region radius will be shrunk if RSHRINK>0.
        ratio = HALF * rshrink
    else
        ! Set ratio to a large negative number to signify a bad trust-region step, so that the
        ! solver will check whether to take a geometry step or reduce RHO.
        ratio = -REALMAX
    end if
elseif (is_posinf(pred) .and. is_posinf(ared)) then
    ratio = ONE  ! ARED/PRED = NaN if calculated directly.
elseif (is_posinf(pred) .and. is_neginf(ared)) then
    ratio = -REALMAX  ! ARED/PRED = NaN if calculated directly.
else
    ratio = ared / pred
end if

!====================!
!  Calculation ends  !
!====================!

! Postconditions
if (DEBUGGING) then
    call assert(.not. is_nan(ratio), 'RATIO is not NaN', srname)
end if

end function redrat


end module ratio_mod
